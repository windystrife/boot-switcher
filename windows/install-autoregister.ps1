#Requires -Version 5
<#
    install-autoregister (Windows) — install a startup scheduled task that keeps
    the UEFI firmware boot menu reduced to two entries (one Linux loader +
    Windows Boot Manager), mirroring the Linux ensure-windows-entry service.
    Self-elevates to Administrator.
#>

$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    return
}

$taskName = 'Ensure Boot Menu'
$destDir  = Join-Path $env:ProgramData 'boot-switcher'
$destPs1  = Join-Path $destDir 'ensure-boot-menu.ps1'

# Copy the worker script to a stable location (survives moving the repo folder).
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item -Force -Path (Join-Path $PSScriptRoot 'ensure-boot-menu.ps1') -Destination $destPs1

$action    = New-ScheduledTaskAction -Execute 'powershell.exe' `
                -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$destPs1`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' `
                -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
                -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Force `
    -Description 'Reduce the UEFI boot menu to Linux + Windows at startup (flaky-firmware helper). https://github.com/windystrife/boot-switcher' `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host "Created startup task '$taskName' -> $destPs1" -ForegroundColor Green
Write-Host "Running it once now..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$destPs1"
Write-Host "Firmware boot order now:" -ForegroundColor Cyan
bcdedit /enum "{fwbootmgr}" | Select-String -Pattern 'displayorder|identifier'

Write-Host "`nUninstall later with:  schtasks /delete /tn `"$taskName`" /f" -ForegroundColor DarkGray
Read-Host "Press Enter to close"
