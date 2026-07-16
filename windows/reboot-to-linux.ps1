#Requires -Version 5
<#
    reboot-to-linux — restart this PC straight into Ubuntu/Linux, one time only.

    Uses the UEFI firmware boot manager (bcdedit {fwbootmgr}) to set a one-time
    boot into the Ubuntu entry, then reboots. The permanent boot order is left
    unchanged, so the boot after this one behaves normally.
#>

# --- self-elevate to Administrator ---------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    return
}

# --- find the Ubuntu firmware boot entry ---------------------------------
$blocks = (bcdedit /enum firmware | Out-String) -split "(\r?\n){2,}"

$targetId = $null
foreach ($block in $blocks) {
    if ($block -match '(?im)^\s*description\s+.*(ubuntu|grub|linux)' -and
        $block -match '(?im)^\s*identifier\s+(\{[0-9A-Fa-f-]+\})') {
        $targetId = $Matches[1]
        break
    }
}

if (-not $targetId) {
    Write-Host "Could not find an Ubuntu/Linux entry in the UEFI firmware boot manager." -ForegroundColor Red
    Write-Host "Run 'bcdedit /enum firmware' to inspect the available entries."
    Read-Host "Press Enter to close"
    return
}

Write-Host "Ubuntu firmware entry: $targetId" -ForegroundColor Cyan
$answer = Read-Host "Restart now and boot into Ubuntu/Linux? [y/N]"
if ($answer -notmatch '^[Yy]') { return }

# --- set one-time boot + reboot ------------------------------------------
bcdedit /set "{fwbootmgr}" bootsequence "$targetId" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "bcdedit failed to set the one-time boot order." -ForegroundColor Red
    Read-Host "Press Enter to close"
    return
}

shutdown /r /t 0
