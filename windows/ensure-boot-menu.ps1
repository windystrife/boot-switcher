<#
    ensure-boot-menu.ps1 (Windows) — make sure Windows Boot Manager stays in the
    UEFI firmware boot menu at each boot, WITHOUT deleting the other entries.

    Mass-deleting entries makes flaky boards (Huananzhi X99) rebuild the whole
    boot list at the next POST and drop the Windows entry — so we only re-assert
    {bootmgr} (added last, so it never becomes the default). Windows itself
    re-creates {bootmgr} on each boot, so this keeps it fresh.

    Meant to run at startup as SYSTEM (installed by install-autoregister.ps1).
#>
$ErrorActionPreference = 'SilentlyContinue'

bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addlast | Out-Null
