#!/usr/bin/env bash

set -euo pipefail

unit="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/new-tab.service"
if [ ! -f "$unit" ]; then
    echo "Run scripts/bootstrap/link-configs.sh before configuring the new tab page." >&2
    exit 1
fi

systemctl --user daemon-reload
systemctl --user enable --now new-tab.service

echo "Set Vimium and New Tab Override to http://127.0.0.1:8766/blank.html"
