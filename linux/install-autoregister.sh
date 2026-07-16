#!/usr/bin/env bash
# Install the "ensure Windows Boot Manager entry" systemd service so it runs at
# every Linux boot. Needs sudo.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -m 0755 "$src/ensure-windows-entry.sh"      /usr/local/sbin/ensure-windows-entry.sh
sudo install -m 0644 "$src/ensure-windows-entry.service" /etc/systemd/system/ensure-windows-entry.service

sudo systemctl daemon-reload
sudo systemctl enable --now ensure-windows-entry.service

echo
echo "Installed. The service re-registers the Windows Boot Manager UEFI entry at"
echo "every boot. Run now / check:"
echo "    sudo systemctl start ensure-windows-entry.service"
echo "    journalctl -u ensure-windows-entry.service -b"
echo "Uninstall:"
echo "    sudo systemctl disable --now ensure-windows-entry.service"
echo "    sudo rm /etc/systemd/system/ensure-windows-entry.service /usr/local/sbin/ensure-windows-entry.sh"
