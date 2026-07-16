<#
    ensure-boot-menu.ps1 (Windows) — mirror of the Linux ensure-windows-entry:
    on each Windows boot, reduce the UEFI firmware boot menu to exactly two
    entries — one Linux loader + Windows Boot Manager ({bootmgr}).

    Deletes the firmware-spawned duplicate Linux entries and sets the firmware
    boot order to [Linux, Windows]. Safe: both bootloaders live on disk, so the
    firmware regenerates whatever it wants on the next POST. Meant to run at
    startup as SYSTEM (installed by install-autoregister.ps1).
#>
$ErrorActionPreference = 'SilentlyContinue'

$fw = bcdedit /enum firmware | Out-String
$blocks = $fw -split "\r?\n\r?\n"

$linux = @()
foreach ($b in $blocks) {
    if ($b -notmatch '(?im)^\s*identifier\s+(\{[^}]+\})') { continue }
    $id = $Matches[1]
    if ($id -match '(?i)fwbootmgr|bootmgr') { continue }   # never touch the fw manager / Windows

    $desc = ''
    if ($b -match '(?im)^\s*description\s+(.+?)\s*$') { $desc = $Matches[1] }

    if ($desc -match '(?i)ubuntu|debian|linux|grub|fedora|arch|manjaro|mint|pop|suse|elementary|zorin|shim' -or
        $b -match '(?i)(grubx64|shimx64|BOOTX64)\.efi') {
        $linux += [pscustomobject]@{ Id = $id; Shim = [bool]($b -match '(?i)shimx64') }
    }
}

if ($linux.Count -ge 1) {
    # Keep one Linux entry (prefer a shim entry — it chains to GRUB); delete the rest.
    $keep = ($linux | Sort-Object -Property @{Expression = 'Shim'; Descending = $true} | Select-Object -First 1).Id
    foreach ($e in $linux) {
        if ($e.Id -ne $keep) { bcdedit /delete "$($e.Id)" /f | Out-Null }
    }
    # Firmware boot order = Linux first (so GRUB shows), Windows second.
    bcdedit /set "{fwbootmgr}" displayorder "$keep" "{bootmgr}" | Out-Null
}
else {
    # No Linux entry visible — at least make sure Windows is in the menu.
    bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addlast | Out-Null
}
