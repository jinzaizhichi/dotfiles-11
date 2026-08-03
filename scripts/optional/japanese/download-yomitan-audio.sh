#!/usr/bin/env bash

set -euo pipefail

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

CACHE_DIR="$XDG_CACHE_HOME/dotfiles/yomitan-audio"
ADDON_DIR="$XDG_DATA_HOME/Anki2/addons21/1045800357"
USER_FILES_DIR="$ADDON_DIR/user_files"
ARCHIVE_NAME="local-yomichan-audio-collection-2023-06-11-opus.tar.xz"
ARCHIVE="$CACHE_DIR/$ARCHIVE_NAME"
MAGNET_URI='magnet:?xt=urn:btih:ef90ec428e6abcd560ffc85a2a1c083e0399d003&dn=local-yomichan-audio-collection-2023-06-11-opus.tar.xz&tr=http%3A%2F%2Fanidex.moe%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce'

collection_installed() {
    [ -f "$USER_FILES_DIR/jmdict_forms.json" ] &&
        [ -d "$USER_FILES_DIR/forvo_files" ] &&
        [ -d "$USER_FILES_DIR/jpod_files" ] &&
        [ -d "$USER_FILES_DIR/nhk16_files" ] &&
        [ -d "$USER_FILES_DIR/shinmeikai8_files" ]
}

if collection_installed; then
    echo "Yomitan local audio is already installed."
    exit
fi

if [ ! -d "$ADDON_DIR" ]; then
    echo "Install Anki add-on 1045800357 before downloading its audio." >&2
    exit 1
fi

command -v aria2c >/dev/null || {
    echo "aria2c is required. Install the aria2 package." >&2
    exit 1
}

mkdir -p "$CACHE_DIR"

if [ ! -f "$ARCHIVE" ]; then
    aria2c --dir="$CACHE_DIR" --seed-time=0 "$MAGNET_URI"
fi

for member in \
    user_files/jmdict_forms.json \
    user_files/forvo_files/ \
    user_files/jpod_files/ \
    user_files/nhk16_files/ \
    user_files/shinmeikai8_files/; do
    tar -tJf "$ARCHIVE" "$member" >/dev/null || {
        echo "$ARCHIVE does not contain the expected audio collection." >&2
        exit 1
    }
done

tar -xJf "$ARCHIVE" -C "$ADDON_DIR" user_files

collection_installed || {
    echo "The audio collection was not extracted correctly." >&2
    exit 1
}

echo "Yomitan local audio installed in $USER_FILES_DIR"
