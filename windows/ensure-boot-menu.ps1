<#
    ensure-boot-menu.ps1 (Windows) — put Windows Boot Manager at boot-priority
    slot #2 (right after a Linux loader) in the UEFI firmware boot order, WITHOUT
    deleting any entries. On flaky boards, mass-deleting entries makes them
    rebuild the boot list at POST and drop Windows; simply moving the Windows
    entry to slot #2 is what keeps it visible.

    Meant to run at startup as SYSTEM (installed by install-autoregister.ps1).
#>
$ErrorActionPreference = 'SilentlyContinue'

# Find a Linux firmware boot entry to sit at slot #1.
$fw = bcdedit /enum firmware | Out-String
$linux = $null
foreach ($b in ($fw -split "\r?\n\r?\n")) {
    if ($b -notmatch '(?im)^\s*identifier\s+(\{[^}]+\})') { continue }
    $id = $Matches[1]
    if ($id -match '(?i)fwbootmgr|bootmgr') { continue }
    $desc = ''
    if ($b -match '(?im)^\s*description\s+(.+?)\s*$') { $desc = $Matches[1] }
    if ($desc -match '(?i)ubuntu|debian|linux|grub|fedora|arch|mint|shim' -or
        $b -match '(?i)(grubx64|shimx64|BOOTX64)\.efi') {
        $linux = $id; break
    }
}

if ($linux) {
    # Linux first (default -> GRUB), Windows second.
    bcdedit /set "{fwbootmgr}" displayorder "$linux" "{bootmgr}" | Out-Null
}
else {
    bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addlast | Out-Null
}
