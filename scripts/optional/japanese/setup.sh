#!/usr/bin/env bash

set -euo pipefail

# ----------------------------
# Config
# ----------------------------

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$scripts_dir/../../.." && pwd)"
OPT="${HOME}/opt"
PREFIX="/usr"

VERSION="26.08"
MPVACIOUS_VERSION="v26.7.28.0"
MPVACIOUS_REF="dotfiles-2026-08-09-v2"
MPVACIOUS_COMMIT="5dc199342d8b98a529170aff1d18bbaec904f877"
MPVACIOUS_REPO="https://github.com/kuator/mpvacious"

ANKI_RELEASE="anki-linux"
ANKI_ARCHIVE="anki-${VERSION}-linux-x86_64.tar.zst"

ANKI_DIR="${OPT}/anki"
ANKI_VERSION_FILE="${ANKI_DIR}/.version"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

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
    echo "Updating Anki to $VERSION"

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

    echo "$VERSION" >"$ANKI_VERSION_FILE"

    echo "Anki $VERSION installed."
else
    echo "Anki $VERSION already installed."
fi

# ----------------------------
# mpv config
# ----------------------------

echo "Setting up mpv..."

mkdir -p "$XDG_CONFIG_HOME"

if [ ! -e "$XDG_CONFIG_HOME/mpv" ] && [ ! -L "$XDG_CONFIG_HOME/mpv" ]; then
    ln -sv "$DOTFILES/configs/xdg/mpv" "$XDG_CONFIG_HOME/mpv"
else
    echo "mpv config already exists."
fi

MPVACIOUS_DIR="$XDG_CONFIG_HOME/mpv/scripts/mpvacious"
mkdir -p "$XDG_CONFIG_HOME/mpv/scripts"

installed_mpvacious_commit=""
if [ -d "$MPVACIOUS_DIR/.git" ]; then
    installed_mpvacious_commit="$(git -C "$MPVACIOUS_DIR" rev-parse HEAD)"
fi

if [ "$installed_mpvacious_commit" != "$MPVACIOUS_COMMIT" ]; then
    rm -rf "$MPVACIOUS_DIR"
    git clone --depth 1 --branch "$MPVACIOUS_REF" \
        "$MPVACIOUS_REPO" "$MPVACIOUS_DIR"
    installed_mpvacious_commit="$(git -C "$MPVACIOUS_DIR" rev-parse HEAD)"
    if [ "$installed_mpvacious_commit" != "$MPVACIOUS_COMMIT" ]; then
        echo "Unexpected mpvacious commit: $installed_mpvacious_commit" >&2
        exit 1
    fi
else
    echo "mpvacious $MPVACIOUS_COMMIT already installed."
fi

printf '{"version": "%s"}' "$MPVACIOUS_VERSION" \
    >"$MPVACIOUS_DIR/mpvacious/version.json"

# ----------------------------
# Anki addons
# ----------------------------

echo "Setting up Anki addons..."

ADDONS_DIR="$XDG_DATA_HOME/Anki2/addons21"
ADDON_MANIFEST="$DOTFILES/japanese/anki/addons.txt"

mkdir -p "$ADDONS_DIR"

missing_addons=()
while IFS=$'\t' read -r addon_id addon_name; do
    if [[ ! "$addon_id" =~ ^[0-9]+$ ]] || [ -z "$addon_name" ]; then
        echo "Invalid AnkiWeb add-on entry: $addon_id $addon_name" >&2
        exit 1
    fi

    [ -d "$ADDONS_DIR/$addon_id" ] || missing_addons+=("$addon_id")
done <"$ADDON_MANIFEST"

if ((${#missing_addons[@]})); then
    printf 'Missing AnkiWeb add-ons:'
    printf ' %s' "${missing_addons[@]}"
    printf '\nPaste these codes into Tools > Add-ons > Get Add-ons.\n'
else
    echo "All AnkiWeb add-ons are installed."
fi

# ----------------------------
# Yomitan audio check
# ----------------------------

echo "Checking Yomitan local audio..."

LOCAL_AUDIO_DIR="$ADDONS_DIR/1045800357/user_files"
if [ -f "$LOCAL_AUDIO_DIR/jmdict_forms.json" ] &&
    [ -d "$LOCAL_AUDIO_DIR/forvo_files" ] &&
    [ -d "$LOCAL_AUDIO_DIR/jpod_files" ] &&
    [ -d "$LOCAL_AUDIO_DIR/nhk16_files" ] &&
    [ -d "$LOCAL_AUDIO_DIR/shinmeikai8_files" ]; then
    echo "Yomitan local audio is installed."
else
    echo "Yomitan local audio is not installed."
    echo "Run download-yomitan-audio.sh after installing add-on 1045800357."
fi

echo "Done."
