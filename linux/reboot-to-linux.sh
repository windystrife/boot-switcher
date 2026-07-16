#!/usr/bin/env bash
# reboot-to-linux — restart this PC back into Linux (the OS you are in now).
#
# Sets the UEFI BootNext variable to the currently-booted entry, so the reboot
# returns to this same OS even if the permanent boot order points elsewhere or
# a one-time BootNext was set earlier. The permanent boot order is NOT changed.
#
# Optional: pass a substring to force which boot entry to use, e.g.
#     reboot-to-linux.sh 0005
set -euo pipefail

force="${1:-}"

find_entry() {
    if [ -n "$force" ]; then
        efibootmgr -v 2>/dev/null | grep -iE "^Boot[0-9A-F]{4}" | grep -i -- "$force" \
            | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/'
        return
    fi
    # The entry we are currently running from — exactly "this OS".
    local e
    e=$(efibootmgr 2>/dev/null | sed -n 's/^BootCurrent:[[:space:]]*//p' | head -n1)
    # Fallback: detect a Linux entry by its GRUB/shim loader path.
    if [ -z "$e" ]; then
        e=$(efibootmgr -v 2>/dev/null | grep -iE '^Boot[0-9A-F]{4}.*(grubx64|shimx64)\.efi' \
            | head -n1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')
    fi
    printf '%s' "$e"
}

fail() {
    if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        zenity --error --title="Reboot to Linux" --text="$1"
    else
        echo "$1" >&2
    fi
    exit 1
}

entry="$(find_entry)"
[ -n "$entry" ] || fail "Could not determine the current Linux boot entry."

if command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    zenity --question --title="Reboot to Linux" \
           --text="Restart now and boot back into Linux (Boot${entry})?" || exit 0
fi

if ! sudo -n efibootmgr -n "$entry" >/dev/null 2>&1; then
    if [ -t 0 ]; then
        sudo efibootmgr -n "$entry" >/dev/null
    else
        fail "Cannot set BootNext: sudo needs a password. Run this once from a terminal, or enable passwordless sudo for efibootmgr."
    fi
fi

systemctl reboot
