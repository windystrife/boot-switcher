#!/usr/bin/env bash
# Install the "Reboot to Windows" launcher for the current user (no root needed).
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin/reboot-to-windows"
desktop_name="reboot-to-windows.desktop"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

install -m 0755 "$src_dir/reboot-to-windows.sh" "$bin"

# Render the .desktop with the real Exec path, then install it to the app menu
# and (if a Desktop folder exists) to the desktop, marked trusted so GNOME runs it.
desktop_dst_menu="$HOME/.local/share/applications/$desktop_name"
sed "s|__BIN__|$bin|g" "$src_dir/$desktop_name" > "$desktop_dst_menu"
chmod 0755 "$desktop_dst_menu"

desk="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$desk" ]; then
    cp "$desktop_dst_menu" "$desk/$desktop_name"
    chmod 0755 "$desk/$desktop_name"
    gio set "$desk/$desktop_name" metadata::trusted true 2>/dev/null || true
fi

command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Installed:"
echo "  launcher : $bin"
echo "  desktop  : ${desk}/$desktop_name"
echo "  app menu : $desktop_dst_menu"
echo
echo "Note: setting UEFI BootNext needs sudo. This works out of the box only if"
echo "passwordless sudo is enabled for efibootmgr; otherwise run the launcher"
echo "once from a terminal to enter your password."
