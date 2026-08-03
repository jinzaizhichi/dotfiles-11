#!/usr/bin/env bash

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles="$(cd "$scripts_dir/../../.." && pwd)"

dconf load /org/gnome/terminal/legacy/profiles:/ <"$dotfiles/configs/gnome-terminal/profile.dconf"
gsettings set org.gnome.Terminal.Legacy.Settings default-show-menubar false
