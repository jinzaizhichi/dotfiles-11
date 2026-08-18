#!/usr/bin/env bash

set -euo pipefail

FORVO_ADDON_ID="580654285"
FORVO_REF="dotfiles-2026-08-15-forvo-timeout"
FORVO_COMMIT="e1c167ef6c0c5de8b2144ae5e88ff3b274262f3b"
FORVO_REPO="https://github.com/kuator/yomichan-forvo-server"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ADDONS_DIR="$XDG_DATA_HOME/Anki2/addons21"
ADDON_DIR="$ADDONS_DIR/$FORVO_ADDON_ID"

mkdir -p "$ADDONS_DIR"

installed_commit=""
if [ -d "$ADDON_DIR/.git" ]; then
	installed_commit="$(git -C "$ADDON_DIR" rev-parse HEAD)"
fi

write_local_meta() {
	local source_meta="${1:-}"
	local target_meta="$2"
	local temp_meta

	temp_meta="$(mktemp "$ADDONS_DIR/.forvo-meta.XXXXXX")"
	if [ -n "$source_meta" ] && [ -f "$source_meta" ]; then
		jq '.name = "Yomichan Forvo Server (kuator fork)" |
            .update_enabled = false' "$source_meta" >"$temp_meta"
	else
		jq -n '{
            name: "Yomichan Forvo Server (kuator fork)",
            disabled: false,
            conflicts: [],
            update_enabled: false
        }' >"$temp_meta"
	fi
	mv "$temp_meta" "$target_meta"
}

if [ "$installed_commit" = "$FORVO_COMMIT" ]; then
	write_local_meta "$ADDON_DIR/meta.json" "$ADDON_DIR/meta.json"
	echo "Yomichan Forvo Server $FORVO_COMMIT already installed."
	exit 0
fi

stage_dir="$(mktemp -d "$ADDONS_DIR/.forvo-server.XXXXXX")"
checkout_dir="$stage_dir/checkout"
previous_dir="$stage_dir/previous"

cleanup() {
	rm -rf "$stage_dir"
}
trap cleanup EXIT

git clone --depth 1 --branch "$FORVO_REF" "$FORVO_REPO" "$checkout_dir"

cloned_commit="$(git -C "$checkout_dir" rev-parse HEAD)"
if [ "$cloned_commit" != "$FORVO_COMMIT" ]; then
	echo "Unexpected Yomichan Forvo Server commit: $cloned_commit" >&2
	exit 1
fi

if [ -f "$ADDON_DIR/config.json" ]; then
	jq -s '.[0] * .[1]' \
		"$checkout_dir/config.json" "$ADDON_DIR/config.json" \
		>"$checkout_dir/config.json.merged"
	mv "$checkout_dir/config.json.merged" "$checkout_dir/config.json"
fi

if [ -d "$ADDON_DIR/user_files" ]; then
	cp -a "$ADDON_DIR/user_files" "$checkout_dir/user_files"
fi

write_local_meta "$ADDON_DIR/meta.json" "$checkout_dir/meta.json"

if [ -e "$ADDON_DIR" ] || [ -L "$ADDON_DIR" ]; then
	mv "$ADDON_DIR" "$previous_dir"
fi

if ! mv "$checkout_dir" "$ADDON_DIR"; then
	if [ -e "$previous_dir" ] || [ -L "$previous_dir" ]; then
		mv "$previous_dir" "$ADDON_DIR"
	fi
	exit 1
fi

rm -rf "$previous_dir"
trap - EXIT
rm -rf "$stage_dir"

echo "Installed Yomichan Forvo Server $FORVO_COMMIT."
echo "Restart Anki to load it."
