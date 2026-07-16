#!/usr/bin/env bash
# reboot-to-windows — restart this PC straight into Windows, one time only.
#
# Sets the UEFI BootNext variable to the Windows Boot Manager entry and
# reboots. The permanent boot order is NOT modified: the boot after this
# one follows the normal order again.
set -euo pipefail

# Find the Windows Boot Manager entry that points at a real ESP file path
# (skips vendor/leftover entries that carry no disk path).
entry=$(efibootmgr -v 2>/dev/null | grep -iE '^Boot[0-9A-F]{4}.*BOOTMGFW\.EFI' | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')

# Fallback: match by entry name only.
if [ -z "${entry}" ]; then
    entry=$(efibootmgr 2>/dev/null | grep -i 'Windows Boot Manager' | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')
fi

if [ -z "${entry}" ]; then
    msg="Windows Boot Manager entry not found in UEFI variables."
    if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        zenity --error --title="Reboot to Windows" --text="$msg"
    else
        echo "$msg" >&2
    fi
    exit 1
fi

# Confirm when running from the desktop (an accidental click should not reboot the box).
if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    zenity --question --title="Reboot to Windows" \
           --text="Restart now and boot into Windows (Boot${entry})?" || exit 0
fi

if ! sudo -n efibootmgr -n "$entry" >/dev/null 2>&1; then
    # sudo needs a password on this system: retry interactively when in a terminal
    if [ -t 0 ]; then
        sudo efibootmgr -n "$entry" >/dev/null
    else
        msg="Cannot set BootNext: sudo requires a password. Run this script from a terminal once, or enable passwordless sudo."
        command -v zenity >/dev/null && zenity --error --title="Reboot to Windows" --text="$msg" || echo "$msg" >&2
        exit 1
    fi
fi

systemctl reboot
