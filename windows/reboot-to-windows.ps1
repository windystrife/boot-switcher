#Requires -Version 5
<#
    reboot-to-windows — restart this PC back into Windows (the OS you are in now).

    Auto-detects the Windows Boot Manager UEFI firmware entry, sets a one-time
    boot into it via bcdedit {fwbootmgr}, and reboots. Useful when the machine's
    default boot order points at another OS but you want to stay on Windows.
    The permanent boot order is left unchanged.

    Optional: pass a substring to force which firmware entry to use, e.g.
        powershell -File reboot-to-windows.ps1 -Match "{a1b2c3d4-...}"
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

# --- find the Windows Boot Manager firmware entry ------------------------
$blocks = (bcdedit /enum firmware | Out-String) -split "(\r?\n){2,}"

$targetId = $null
$candidates = @()

foreach ($block in $blocks) {
    if ($block -notmatch '(?im)^\s*identifier\s+(\{[0-9A-Fa-f-]+\})') { continue }
    $id = $Matches[1]

    $desc = ''
    if ($block -match '(?im)^\s*description\s+(.+?)\s*$') { $desc = $Matches[1] }

    if ($Match) {
        if ($desc -like "*$Match*" -or $id -like "*$Match*") { $targetId = $id; break }
        continue
    }

    if ($id -match '(?i)fwbootmgr') { continue }

    # Windows by name, or by its universal BOOTMGFW.EFI loader path.
    if ($desc -match '(?i)windows boot manager' -or $block -match '(?i)\\EFI\\.*bootmgfw\.efi') {
        $candidates += [pscustomobject]@{ Id = $id; Desc = $desc; HasPath = ($block -match '(?i)bootmgfw\.efi') }
    }
}

# Prefer a candidate that carries a real BOOTMGFW path over a bare name entry.
if (-not $targetId -and $candidates.Count -ge 1) {
    $best = $candidates | Sort-Object -Property @{Expression='HasPath';Descending=$true} | Select-Object -First 1
    $targetId = $best.Id
}

if (-not $targetId) {
    Write-Host "No Windows Boot Manager entry found in the UEFI firmware boot manager." -ForegroundColor Red
    bcdedit /enum firmware | Select-String -Pattern 'identifier|description'
    Read-Host "Press Enter to close"
    return
}

$name = ($candidates | Where-Object Id -eq $targetId | Select-Object -First 1).Desc
if (-not $name) { $name = $targetId }
Write-Host "Windows firmware entry: $name  $targetId" -ForegroundColor Cyan
$answer = Read-Host "Restart now and boot back into Windows? [y/N]"
if ($answer -notmatch '^[Yy]') { return }

# --- set one-time boot + reboot ------------------------------------------
bcdedit /set "{fwbootmgr}" bootsequence "$targetId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "bcdedit failed to set the one-time boot order." -ForegroundColor Red
    Read-Host "Press Enter to close"
    return
}

shutdown /r /t 0
