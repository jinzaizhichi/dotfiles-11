#!/usr/bin/env bash

set -euo pipefail

TEXTRACTOR_VERSION="260801"
TEXTRACTOR_SHA256="86346c71ba961e993b8b40419d8720204ccaf8fe20606bbd267eb765ba2ff2ef"
TEXTRACTOR_URL="https://github.com/Chenx221/Textractor/releases/download/dev/Textractor_${TEXTRACTOR_VERSION}.zip"
PROTONTRICKS_VERSION="1.13.1"

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
release_root="$data_home/textractor/releases"
release_dir="$release_root/$TEXTRACTOR_VERSION"
current="$data_home/textractor/current"
marker="$release_dir/.archive-sha256"

architecture="${DEB_ARCHITECTURE:-$(dpkg --print-architecture)}"
if [ "$architecture" != amd64 ]; then
	printf 'Unsupported architecture for Textractor under Proton: %s\n' \
		"$architecture" >&2
	exit 1
fi

protontricks_version="$(
	protontricks --version 2>/dev/null |
		sed -n 's/^protontricks (\([^)]*\)).*/\1/p' || true
)"
if [ "$protontricks_version" != "$PROTONTRICKS_VERSION" ]; then
	command -v uv >/dev/null 2>&1 || {
		echo 'uv is required to install the pinned Protontricks release.' >&2
		exit 1
	}
	uv tool install --force "protontricks==$PROTONTRICKS_VERSION"
fi

if [ ! -f "$marker" ] ||
	[ "$(cat "$marker" 2>/dev/null || true)" != "$TEXTRACTOR_SHA256" ] ||
	[ ! -f "$release_dir/x86/Textractor.exe" ] ||
	[ ! -f "$release_dir/x64/Textractor.exe" ]; then
	if [ -e "$release_dir" ]; then
		echo "Refusing to replace incomplete Textractor release: $release_dir" >&2
		exit 1
	fi

	staging_root="$(mktemp -d)"
	cleanup() {
		rm -rf "$staging_root"
	}
	trap cleanup EXIT
	archive="$staging_root/Textractor_${TEXTRACTOR_VERSION}.zip"
	extracted="$staging_root/extracted"

	if [ -n "${TEXTRACTOR_ARCHIVE:-}" ]; then
		cp "$TEXTRACTOR_ARCHIVE" "$archive"
	else
		curl --fail --silent --show-error --location \
			--output "$archive" "$TEXTRACTOR_URL"
	fi
	printf '%s  %s\n' "$TEXTRACTOR_SHA256" "$archive" |
		sha256sum --check --status

	if unzip -Z1 "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
		echo 'Textractor archive contains an unsafe path.' >&2
		exit 1
	fi
	mkdir -p "$extracted"
	unzip -q "$archive" -d "$extracted"
	for required in \
		x86/Textractor.exe x86/texthook.dll \
		x64/Textractor.exe x64/texthook.dll \
		INSTALL_THIS_UNICODE_FONT.ttf; do
		[ -f "$extracted/$required" ] || {
			echo "Textractor archive is missing $required." >&2
			exit 1
		}
	done

	printf '%s\n' "$TEXTRACTOR_SHA256" >"$extracted/.archive-sha256"
	mkdir -p "$release_root"
	mv "$extracted" "$release_dir"
fi

if [ -e "$current" ] && [ ! -L "$current" ]; then
	echo "Refusing to replace non-symlink Textractor current path: $current" >&2
	exit 1
fi
if [ ! -L "$current" ] ||
	[ "$(readlink "$current")" != "releases/$TEXTRACTOR_VERSION" ]; then
	ln -sfn "releases/$TEXTRACTOR_VERSION" "$current"
fi

font_dir="$data_home/fonts"
font="$font_dir/Textractor-Unicode.ttf"
if [ ! -f "$font" ] || ! cmp -s "$release_dir/INSTALL_THIS_UNICODE_FONT.ttf" "$font"; then
	mkdir -p "$font_dir"
	install -m 0644 "$release_dir/INSTALL_THIS_UNICODE_FONT.ttf" "$font"
	command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null
fi

echo "Textractor $TEXTRACTOR_VERSION installed in $release_dir."
