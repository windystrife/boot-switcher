#Requires -Version 5
<#
    reboot-to-windows — restart this PC back into Windows (the OS you are in now).

    Sets a one-time boot into the Windows Boot Manager via bcdedit {fwbootmgr}
    and reboots. Windows Boot Manager's firmware identifier is the well-known
    {bootmgr}, so no fragile parsing is needed. The permanent boot order is
    left unchanged.

    Optional: pass a specific firmware entry to force it, e.g.
        powershell -File reboot-to-windows.ps1 -Match "{bootmgr}"
        powershell -File reboot-to-windows.ps1 -Match "Windows"
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

$fw = bcdedit /enum firmware | Out-String

# --- pick the target firmware entry --------------------------------------
$targetId = $null

if ($Match) {
    # If a whole {id} was given, use it as-is; otherwise search by name/id.
    if ($Match -match '^\{.+\}$') {
        $targetId = $Match
    }
    else {
        foreach ($block in ($fw -split "\r?\n\r?\n")) {
            if ($block -match '(?im)^\s*identifier\s+(\{[^}]+\})') {
                $id = $Matches[1]
                $desc = if ($block -match '(?im)^\s*description\s+(.+?)\s*$') { $Matches[1] } else { '' }
                if ($desc -like "*$Match*" -or $id -like "*$Match*") { $targetId = $id; break }
            }
        }
    }
}
else {
    # Windows Boot Manager's firmware identifier is the well-known {bootmgr}.
    if ($fw -match '(?im)^\s*identifier\s+\{bootmgr\}') {
        $targetId = '{bootmgr}'
    }
    else {
        # Fallback: match by description or the BOOTMGFW.EFI loader path.
        foreach ($block in ($fw -split "\r?\n\r?\n")) {
            if ($block -match '(?im)^\s*identifier\s+(\{[^}]+\})') {
                $id = $Matches[1]
                if ($id -match '(?i)fwbootmgr') { continue }
                if ($block -match '(?i)windows boot manager' -or $block -match '(?i)bootmgfw\.efi') {
                    $targetId = $id; break
                }
            }
        }
    }
}

if (-not $targetId) {
    Write-Host "Could not find the Windows Boot Manager firmware entry." -ForegroundColor Red
    bcdedit /enum firmware | Select-String -Pattern 'identifier|description'
    Read-Host "Press Enter to close"
    return
}

Write-Host "Windows firmware entry: $targetId" -ForegroundColor Cyan
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
