#!/usr/bin/env bash

set -euo pipefail

unit="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/xm6-audio-guard.service"
if [ ! -f "$unit" ]; then
	echo "Run scripts/bootstrap/link-configs.sh before configuring the XM6 audio guard." >&2
	exit 1
fi

systemctl --user daemon-reload
systemctl --user enable --now xm6-audio-guard.service

echo "XM6 audio guard enabled."
