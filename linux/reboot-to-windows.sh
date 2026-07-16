#!/usr/bin/env bash
# reboot-to-windows — restart this PC straight into Windows, one time only.
#
# Auto-detects the Windows Boot Manager UEFI entry (matches the universal
# BOOTMGFW.EFI boot path, so it works on any UEFI machine — no drive or entry
# number is hard-coded), sets the UEFI BootNext variable to it, and reboots.
# The permanent boot order is NOT modified.
#
# Optional: pass a substring to force which boot entry to use, e.g.
#     reboot-to-windows.sh "Windows"
#     reboot-to-windows.sh 0006
set -euo pipefail

force="${1:-}"

find_entry() {
    if [ -n "$force" ]; then
        efibootmgr -v 2>/dev/null | grep -iE "^Boot[0-9A-F]{4}" | grep -i -- "$force" \
            | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/'
        return
    fi
    # Primary: the standard Windows UEFI loader path (works on every Windows install).
    local e
    e=$(efibootmgr -v 2>/dev/null | grep -iE '^Boot[0-9A-F]{4}.*BOOTMGFW\.EFI' \
        | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')
    # Fallback: match by the entry name.
    if [ -z "$e" ]; then
        e=$(efibootmgr 2>/dev/null | grep -i 'Windows Boot Manager' \
            | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')
    fi
    printf '%s' "$e"
}

fail() {
    if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        zenity --error --title="Reboot to Windows" --text="$1"
    else
        echo "$1" >&2
    fi
    exit 1
}

entry="$(find_entry)"
[ -n "$entry" ] || fail "Windows Boot Manager entry not found in the UEFI boot menu."

# Confirm when launched from the desktop (an accidental click must not reboot the box).
if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    zenity --question --title="Reboot to Windows" \
           --text="Restart now and boot into Windows (Boot${entry})?" || exit 0
fi

if ! sudo -n efibootmgr -n "$entry" >/dev/null 2>&1; then
    if [ -t 0 ]; then
        sudo efibootmgr -n "$entry" >/dev/null
    else
        fail "Cannot set BootNext: sudo needs a password. Run this once from a terminal, or enable passwordless sudo for efibootmgr."
    fi
fi

systemctl reboot
