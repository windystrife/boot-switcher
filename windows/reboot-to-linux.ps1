#Requires -Version 5
<#
    reboot-to-linux — restart this PC straight into Linux, one time only.

    Auto-detects the Linux UEFI firmware boot entry (by name or by GRUB/shim
    boot path), sets a one-time boot into it via bcdedit {fwbootmgr}, and
    reboots. The permanent boot order is left unchanged.

    Works on any UEFI machine, no drive/entry is hard-coded.

    Optional: pass a substring to force which firmware entry to use, e.g.
        powershell -File reboot-to-linux.ps1 -Match fedora
        powershell -File reboot-to-linux.ps1 -Match "{a1b2c3d4-...}"
#>
param([string]$Match)

# --- self-elevate to Administrator ---------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Match) { $argList += " -Match `"$Match`"" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    return
}

# --- parse firmware boot entries -----------------------------------------
$blocks = (bcdedit /enum firmware | Out-String) -split "(\r?\n){2,}"

# Common Linux distro / bootloader names, plus the universal GRUB/shim paths.
$linuxName = '(?i)ubuntu|debian|linux|grub|shim|fedora|arch|manjaro|pop.?os|' +
             'opensuse|suse|mint|endeavour|elementary|zorin|garuda|nobara|' +
             'kali|rocky|alma|gentoo|void|nixos|mx.?linux'
$linuxPath = '(?i)\\EFI\\.*(grubx64|shimx64|grub)\.efi'

$targetId = $null
$candidates = @()

foreach ($block in $blocks) {
    if ($block -notmatch '(?im)^\s*identifier\s+(\{[0-9A-Fa-f-]+\})') { continue }
    $id = $Matches[1]

    $desc = ''
    if ($block -match '(?im)^\s*description\s+(.+?)\s*$') { $desc = $Matches[1] }

    # If the user forced a match, honour it (against description or identifier).
    if ($Match) {
        if ($desc -like "*$Match*" -or $id -like "*$Match*") { $targetId = $id; break }
        continue
    }

    # Skip the firmware boot manager itself and anything Windows.
    if ($id -match '(?i)fwbootmgr' -or $desc -match '(?i)windows boot manager') { continue }

    if ($desc -match $linuxName -or $block -match $linuxPath) {
        $candidates += [pscustomobject]@{ Id = $id; Desc = $desc }
    }
}

if (-not $targetId -and $candidates.Count -ge 1) { $targetId = $candidates[0].Id }

if (-not $targetId) {
    Write-Host "No Linux entry found in the UEFI firmware boot manager." -ForegroundColor Red
    Write-Host "Firmware entries available:`n"
    bcdedit /enum firmware | Select-String -Pattern 'identifier|description'
    Write-Host "`nRe-run with a name to force it, e.g.:  reboot-to-linux.ps1 -Match fedora"
    Read-Host "Press Enter to close"
    return
}

$name = ($candidates | Where-Object Id -eq $targetId | Select-Object -First 1).Desc
if (-not $name) { $name = $targetId }
Write-Host "Linux firmware entry: $name  $targetId" -ForegroundColor Cyan
$answer = Read-Host "Restart now and boot into Linux? [y/N]"
if ($answer -notmatch '^[Yy]') { return }

# --- set one-time boot + reboot ------------------------------------------
bcdedit /set "{fwbootmgr}" bootsequence "$targetId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "bcdedit failed to set the one-time boot order." -ForegroundColor Red
    Read-Host "Press Enter to close"
    return
}

shutdown /r /t 0
