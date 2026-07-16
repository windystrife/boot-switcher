#!/usr/bin/env bash
# Install the "Reboot to Windows" and "Reboot to Linux" launchers for the
# current user (no root needed). Adds icons to the desktop and app menu.
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
desk="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"

install_one() {
    local script="$1" desktop="$2" binname="$3"
    local bin="$HOME/.local/bin/$binname"

    install -m 0755 "$src_dir/$script" "$bin"

    local menu="$HOME/.local/share/applications/$desktop"
    sed "s|__BIN__|$bin|g" "$src_dir/$desktop" > "$menu"
    chmod 0755 "$menu"

    if [ -d "$desk" ]; then
        cp "$menu" "$desk/$desktop"
        chmod 0755 "$desk/$desktop"
        gio set "$desk/$desktop" metadata::trusted true 2>/dev/null || true
    fi
    echo "  installed: $desk/$desktop  ->  $bin"
}

install_one reboot-to-windows.sh reboot-to-windows.desktop reboot-to-windows
install_one reboot-to-linux.sh   reboot-to-linux.desktop   reboot-to-linux

command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo
echo "Done. Two launchers are on your desktop and in the applications menu:"
echo "  - Reboot to Windows  (boot into Windows next)"
echo "  - Reboot to Linux    (restart back into Linux)"
echo
echo "Note: setting the UEFI boot target needs sudo. It runs without a prompt"
echo "only if passwordless sudo is enabled for efibootmgr; otherwise launch"
echo "each once from a terminal to enter your password."
