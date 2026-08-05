#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
keyboard_config="$repo/configs/system/keyboard"
xkb_symbols="$repo/configs/system/xkb/symbols/tilde-first"
. "$keyboard_config"
sudo install -m 644 "$xkb_symbols" /usr/share/X11/xkb/symbols/tilde-first
sudo install -m 644 "$keyboard_config" /etc/default/keyboard

configure_cinnamon() {
	command -v gsettings >/dev/null || return

	if gsettings list-schemas | grep -qx org.freedesktop.ibus.general; then
		gsettings set org.freedesktop.ibus.general use-system-keyboard-layout true
	fi

	if gsettings list-schemas | grep -qx org.cinnamon.desktop.input-sources; then
		gsettings reset org.cinnamon.desktop.input-sources sources
		gsettings reset org.cinnamon.desktop.input-sources xkb-options
	fi

	if gsettings list-schemas | grep -qx org.gnome.libgnomekbd.keyboard; then
		gsettings reset org.gnome.libgnomekbd.keyboard layouts
		gsettings reset org.gnome.libgnomekbd.keyboard options
		gsettings reset org.gnome.libgnomekbd.keyboard model
	fi

	if gsettings list-schemas | grep -qx org.cinnamon.desktop.peripherals.keyboard; then
		gsettings set org.cinnamon.desktop.peripherals.keyboard delay 220
		gsettings set org.cinnamon.desktop.peripherals.keyboard repeat-interval 25
	fi
}

configure_kde() {
	local writer

	if command -v kwriteconfig6 >/dev/null; then
		writer=kwriteconfig6
	elif command -v kwriteconfig5 >/dev/null; then
		writer=kwriteconfig5
	else
		return
	fi

	"$writer" --file kxkbrc --group Layout --key Use true
	"$writer" --file kxkbrc --group Layout --key ResetOldOptions true
	"$writer" --file kxkbrc --group Layout --key LayoutList "$XKBLAYOUT"
	"$writer" --file kxkbrc --group Layout --key VariantList "$XKBVARIANT"
	"$writer" --file kxkbrc --group Layout --key Options "$XKBOPTIONS"
	"$writer" --file kcminputrc --group Keyboard --key KeyRepeat repeat
	"$writer" --file kcminputrc --group Keyboard --key RepeatDelay 220
	"$writer" --file kcminputrc --group Keyboard --key RepeatRate 40
}

case "${XDG_CURRENT_DESKTOP:-}" in
*Cinnamon*) configure_cinnamon ;;
*KDE*) configure_kde ;;
esac

if [ -n "${DISPLAY:-}" ] && command -v setxkbmap >/dev/null; then
	setxkbmap -layout "$XKBLAYOUT" -variant "$XKBVARIANT" \
		-option '' -option "$XKBOPTIONS"
fi
