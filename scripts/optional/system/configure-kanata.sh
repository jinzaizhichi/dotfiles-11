#!/usr/bin/env bash

# https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md

set -euo pipefail

unit="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/kanata.service"
if [ ! -f "$unit" ]; then
	echo "Run scripts/bootstrap/link-configs.sh before configuring Kanata." >&2
	exit 1
fi

sudo groupadd --system -f uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
sudo udevadm control --reload-rules
sudo modprobe uinput
sudo udevadm trigger

systemctl --user daemon-reload
systemctl --user enable kanata.service
systemctl --user restart kanata.service

echo "Kanata is configured. Log out and back in to apply new group membership."
