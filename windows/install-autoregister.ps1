#Requires -Version 5
<#
    install-autoregister — create a startup scheduled task that re-asserts the
    Windows Boot Manager in the UEFI firmware boot menu at every Windows boot.
    For flaky boards that drop/hide the Windows entry after a Windows boot.
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

$taskName = 'Register Windows Boot Manager'

$action    = New-ScheduledTaskAction -Execute 'bcdedit.exe' `
                -Argument '/set {fwbootmgr} displayorder {bootmgr} /addlast'
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' `
                -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
                -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Force `
    -Description 'Re-assert Windows Boot Manager in the UEFI boot menu at startup (flaky-firmware helper). https://github.com/windystrife/boot-switcher' `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host "Created startup task '$taskName' (runs bcdedit at each boot)." -ForegroundColor Green
Write-Host "Running it once now..."
& bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addlast

Write-Host "`nUninstall later with:  schtasks /delete /tn `"$taskName`" /f" -ForegroundColor DarkGray
Read-Host "Press Enter to close"
