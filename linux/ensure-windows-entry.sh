#!/usr/bin/env bash
# ensure-windows-entry — (re)register a "Windows Boot Manager" UEFI entry that
# points at the Windows ESP, keeping Linux first and Windows second in the boot
# order. Meant to run at every Linux boot (systemd) on flaky firmwares that
# "forget"/hide the Windows entry after a Windows boot.
#
# Nothing here is machine-specific: the Windows ESP is found by scanning for the
# partition that actually holds \EFI\Microsoft\Boot\bootmgfw.efi.
set -uo pipefail

LABEL="Windows Boot Manager"
LOADER='\EFI\Microsoft\Boot\bootmgfw.efi'
ESP_GUID="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"   # EFI System Partition type GUID

log() { logger -t ensure-windows-entry "$*" 2>/dev/null || true; echo "ensure-windows-entry: $*"; }

[ -d /sys/firmware/efi ] || { log "not a UEFI system — skipping"; exit 0; }

# 1) Locate the ESP that holds the Windows bootloader.
winpart=""
while read -r name parttype; do
    [ "${parttype,,}" = "$ESP_GUID" ] || continue
    dev="/dev/$name"
    mp=$(mktemp -d)
    if mount -o ro "$dev" "$mp" 2>/dev/null; then
        [ -f "$mp/EFI/Microsoft/Boot/bootmgfw.efi" ] && winpart="$dev"
        umount "$mp" 2>/dev/null || true
    fi
    rmdir "$mp" 2>/dev/null || true
    [ -n "$winpart" ] && break
done < <(lsblk -rno NAME,PARTTYPE)

[ -n "$winpart" ] || { log "Windows ESP not found — nothing to do"; exit 0; }

pk=$(lsblk -no PKNAME "$winpart" | head -1)
disk="/dev/$pk"
partnum=$(cat "/sys/class/block/$(basename "$winpart")/partition" 2>/dev/null)
[ -n "$partnum" ] || { log "cannot read partition number for $winpart"; exit 0; }
log "Windows ESP: $winpart (disk $disk, part $partnum)"

# 2) Create a fresh entry — a freshly-created entry is what these firmwares re-show.
efibootmgr -c -d "$disk" -p "$partnum" -L "$LABEL" -l "$LOADER" >/dev/null 2>&1 || {
    log "efibootmgr -c failed"; exit 0; }

# 3) Keep the newest Windows entry; delete ONLY older duplicate Windows entries.
#    (Do NOT delete the Linux entries — mass deletion makes this firmware rebuild
#    its whole boot list at the next POST and drop the Windows entry. A freshly
#    created Windows entry, added without deleting the others, is what actually
#    shows up in the BIOS menu on these Huananzhi boards.)
mapfile -t wins < <(efibootmgr -v | grep -i "$LABEL" | grep -i bootmgfw | sed -E 's/^Boot([0-9A-Fa-f]{4}).*/\1/')
[ "${#wins[@]}" -ge 1 ] || { log "no Windows entry after create (?)"; exit 0; }
keep_win="${wins[-1]}"
for b in "${wins[@]}"; do
    [ "$b" != "$keep_win" ] && efibootmgr -b "$b" -B >/dev/null 2>&1 || true
done

# 4) Put the Linux entry we booted from first, the fresh Windows entry second,
#    and keep all the other entries after them.
cur=$(efibootmgr | sed -n 's/^BootCurrent: //p')
rest=$(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n' | grep -vx "$cur" | grep -vx "$keep_win" | paste -sd,)
if [ -n "$cur" ]; then
    efibootmgr -o "${cur},${keep_win}${rest:+,$rest}" >/dev/null 2>&1 || true
fi
log "refreshed Boot$keep_win ($LABEL); order = $(efibootmgr | sed -n 's/^BootOrder: //p')"
