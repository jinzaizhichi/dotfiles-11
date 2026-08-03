#!/usr/bin/env bash

set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
fixsteam_dir="$data_home/fixsteam"
fixsteam_url="https://raw.githubusercontent.com/Samueru-sama/fixsteam/main/steam"
steam_url="https://repo.steampowered.com/steam/archive/stable/steam_latest.deb"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

curl -fsSL "$fixsteam_url" -o "$temporary/steam"
curl -fL "$steam_url" -o "$temporary/steam.deb"
sudo apt-get install -y gcc libc6-dev-i386 "$temporary/steam.deb"

mkdir -p "$fixsteam_dir"
install -m 755 "$temporary/steam" "$fixsteam_dir/steam"

echo "Steam and fixsteam installed. Run steam once to finish setup."
