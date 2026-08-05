#!/usr/bin/env bash

set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles="$(cd "$scripts_dir/../../.." && pwd)"
dconf_bin="${DCONF_BIN:-dconf}"
gsettings_bin="${GSETTINGS_BIN:-gsettings}"

if ! command -v "$dconf_bin" >/dev/null ||
    ! command -v "$gsettings_bin" >/dev/null ||
    ! "$gsettings_bin" list-schemas | grep -Fqx org.gnome.Terminal.Legacy.Settings; then
    echo 'GNOME Terminal is not installed. Run this script only on Ubuntu Cinnamon with GNOME Terminal.' >&2
    exit 1
fi

"$dconf_bin" load /org/gnome/terminal/legacy/profiles:/ <"$dotfiles/configs/gnome-terminal/profile.dconf"
"$gsettings_bin" set org.gnome.Terminal.Legacy.Settings default-show-menubar false
