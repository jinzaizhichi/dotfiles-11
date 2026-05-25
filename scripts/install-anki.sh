#!/usr/bin/env bash

set -euo pipefail

# ----------------------------
# Config
# ----------------------------

OPT="${HOME}/opt"
PREFIX="/usr"

VERSION="25.09"

ANKI_RELEASE="anki-launcher-${VERSION}-linux"
ANKI_ARCHIVE="${ANKI_RELEASE}.tar.zst"

ANKI_DIR="${OPT}/anki"
ANKI_VERSION_FILE="${ANKI_DIR}/.version"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

LOCAL_YOMICHAN_AUDIO_FILE="$HOME/Downloads/local-yomichan-audio-collection-2023-06-11-opus.tar.xz"

# ----------------------------
# Install / upgrade Anki
# ----------------------------

echo "Checking Anki..."

mkdir -p "$OPT"
cd "$OPT"

CURRENT_VERSION=""

if [ -f "$ANKI_VERSION_FILE" ]; then
    CURRENT_VERSION="$(cat "$ANKI_VERSION_FILE")"
fi

if [ "$CURRENT_VERSION" != "$VERSION" ]; then
    echo "Updating Anki launcher to $VERSION"

    # uninstall previous launcher install
    if [ -d "$ANKI_DIR" ] && [ -f "$ANKI_DIR/uninstall.sh" ]; then
        echo "Removing previous launcher install..."

        (
            cd "$ANKI_DIR"
            sudo PREFIX="$PREFIX" ./uninstall.sh || true
        )
    fi

    # remove old launcher dir
    rm -rf "$ANKI_DIR"

    # download archive if needed
    if [ ! -f "$ANKI_ARCHIVE" ]; then
        URL="https://github.com/ankitects/anki/releases/download/${VERSION}/${ANKI_ARCHIVE}"

        echo "Downloading:"
        echo "$URL"

        wget "$URL"
    else
        echo "Archive already exists."
    fi

    echo "Extracting launcher..."

    rm -rf "$ANKI_RELEASE"

    tar --zstd -xvf "$ANKI_ARCHIVE"

    mv "$ANKI_RELEASE" "$ANKI_DIR"

    cd "$ANKI_DIR"

    echo "Installing launcher..."
    sudo PREFIX="$PREFIX" ./install.sh

    echo "$VERSION" > "$ANKI_VERSION_FILE"

    echo "Anki $VERSION installed."
else
    echo "Anki $VERSION already installed."
fi

# ----------------------------
# mpv config
# ----------------------------

echo "Setting up mpv..."

mkdir -p "$XDG_CONFIG_HOME"

if [ ! -e "$XDG_CONFIG_HOME/mpv" ]; then
    ln -sv "$DOTFILES/mpv" "$XDG_CONFIG_HOME/mpv"
else
    echo "mpv config already exists."
fi

mkdir -p "$XDG_CONFIG_HOME/mpv/scripts"

if [ ! -d "$XDG_CONFIG_HOME/mpv/scripts/mpvacious" ]; then
    git clone \
        https://github.com/Ajatt-Tools/mpvacious \
        "$XDG_CONFIG_HOME/mpv/scripts/mpvacious"
else
    echo "mpvacious already installed."
fi

# ----------------------------
# Anki addons
# ----------------------------

echo "Setting up Anki addons..."

ADDONS_DIR="$XDG_DATA_HOME/Anki2/addons21"

mkdir -p "$ADDONS_DIR"

# copy local addons only if addons folder is empty
if [ -d "$DOTFILES/anki/addons21" ]; then
    if [ -z "$(find "$ADDONS_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]; then
        echo "Copying local addons..."

        cp -r \
            "$DOTFILES/anki/addons21/"* \
            "$ADDONS_DIR/"
    else
        echo "Anki addons already exist."
    fi
fi

# Japanese
if [ ! -d "$ADDONS_DIR/1344485230" ]; then
    echo "Installing Japanese addon..."

    git clone \
        https://github.com/Ajatt-Tools/Japanese.git \
        --recurse-submodules \
        -j8 \
        "$ADDONS_DIR/1344485230"
else
    echo "Japanese addon already installed."
fi

# ----------------------------
# Yomichan audio check
# ----------------------------

echo "Checking Yomichan audio collection..."

if [ -f "$LOCAL_YOMICHAN_AUDIO_FILE" ]; then
    echo "$LOCAL_YOMICHAN_AUDIO_FILE exists."
else
    echo "$LOCAL_YOMICHAN_AUDIO_FILE does not exist."
    exit 1
fi

echo "Done."
