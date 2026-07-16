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

# 2) Keep a STABLE Windows entry — only create one if none exists. Recreating it
#    every boot changes its number and seems to make the firmware churn; a stable
#    entry that we simply move to slot #2 is what actually stays visible in BIOS.
keep_win=$(efibootmgr -v | grep -i "$LABEL" | grep -i bootmgfw | head -1 | sed -E 's/^Boot([0-9A-Fa-f]{4}).*/\1/')
if [ -z "$keep_win" ]; then
    efibootmgr -c -d "$disk" -p "$partnum" -L "$LABEL" -l "$LOADER" >/dev/null 2>&1 || {
        log "efibootmgr -c failed"; exit 0; }
    keep_win=$(efibootmgr -v | grep -i "$LABEL" | grep -i bootmgfw | head -1 | sed -E 's/^Boot([0-9A-Fa-f]{4}).*/\1/')
    log "created Windows entry Boot$keep_win"
fi
[ -n "$keep_win" ] || { log "no Windows entry available"; exit 0; }

# 3) Delete only DUPLICATE Windows entries (keep our one). Don't touch Linux.
for b in $(efibootmgr -v | grep -i "$LABEL" | grep -i bootmgfw | sed -E 's/^Boot([0-9A-Fa-f]{4}).*/\1/'); do
    [ "$b" != "$keep_win" ] && efibootmgr -b "$b" -B >/dev/null 2>&1 || true
done

# 4) Move Windows to boot-priority slot #2: Linux (the entry we booted) first,
#    Windows second, the rest after. This is the part that makes BIOS show it.
cur=$(efibootmgr | sed -n 's/^BootCurrent: //p')
rest=$(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n' | grep -vx "$cur" | grep -vx "$keep_win" | paste -sd,)
if [ -n "$cur" ]; then
    efibootmgr -o "${cur},${keep_win}${rest:+,$rest}" >/dev/null 2>&1 || true
fi
log "Windows Boot$keep_win at slot #2; order = $(efibootmgr | sed -n 's/^BootOrder: //p')"
