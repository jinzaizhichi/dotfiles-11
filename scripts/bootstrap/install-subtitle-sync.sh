#!/usr/bin/env bash

set -euo pipefail

FFSUBSYNC_VERSION="0.4.31"
ALASS_VERSION="2.0.0"
AUTOSUBSYNC_REPO="https://github.com/Ajatt-Tools/autosubsync-mpv.git"
AUTOSUBSYNC_COMMIT="a6dc1bbf86d82d001b34c6b223d1f82ee3d7b2cc"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"
MPV_SCRIPTS_DIR="${MPV_SCRIPTS_DIR:-$XDG_CONFIG_HOME/mpv/scripts}"
LOCAL_BIN="$HOME/.local/bin"
CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-$LOCAL_BIN}"
UV_TOOL_DIR="${UV_TOOL_DIR:-$XDG_DATA_HOME/uv/tools}"
export CARGO_HOME UV_TOOL_BIN_DIR UV_TOOL_DIR

if [ ! -x "$MISE_BIN" ]; then
    echo "Mise is not installed at $MISE_BIN." >&2
    exit 1
fi

mkdir -p "$LOCAL_BIN" "$MPV_SCRIPTS_DIR"

echo "Checking ffsubsync..."
if "$MISE_BIN" exec -- uv tool list | grep -Fqx "ffsubsync v$FFSUBSYNC_VERSION"; then
    echo "ffsubsync $FFSUBSYNC_VERSION already installed with uv."
else
    "$MISE_BIN" exec -- uv tool install --force "ffsubsync==$FFSUBSYNC_VERSION"
fi

if [ "$("$UV_TOOL_BIN_DIR/ffsubsync" --version)" != "ffsubsync $FFSUBSYNC_VERSION" ]; then
    echo "Unexpected ffsubsync version." >&2
    exit 1
fi

echo "Checking alass..."
alass_cli="$CARGO_HOME/bin/alass-cli"
installed_alass_version=""
if [ -x "$alass_cli" ]; then
    installed_alass_version="$("$alass_cli" --version)"
fi
if [ "$installed_alass_version" != "alass-cli $ALASS_VERSION" ]; then
    "$MISE_BIN" exec -- cargo install --locked --version "$ALASS_VERSION" alass-cli
else
    echo "alass-cli $ALASS_VERSION already installed."
fi
ln -sfn "$alass_cli" "$LOCAL_BIN/alass"

if [ "$("$LOCAL_BIN/alass" --version)" != "alass-cli $ALASS_VERSION" ]; then
    echo "Unexpected alass version." >&2
    exit 1
fi

echo "Checking autosubsync-mpv..."
autosubsync_dir="$MPV_SCRIPTS_DIR/autosubsync-mpv"
installed_autosubsync_commit=""
if [ -d "$autosubsync_dir/.git" ]; then
    installed_autosubsync_commit="$(git -C "$autosubsync_dir" rev-parse HEAD)"
fi

if [ "$installed_autosubsync_commit" = "$AUTOSUBSYNC_COMMIT" ]; then
    echo "autosubsync-mpv $AUTOSUBSYNC_COMMIT already installed."
else
    staging_root="$(mktemp -d)"
    trap 'rm -rf "$staging_root"' EXIT
    staging_dir="$staging_root/autosubsync-mpv"

    git clone --no-checkout "$AUTOSUBSYNC_REPO" "$staging_dir"
    git -C "$staging_dir" checkout --detach "$AUTOSUBSYNC_COMMIT"
    staged_commit="$(git -C "$staging_dir" rev-parse HEAD)"
    if [ "$staged_commit" != "$AUTOSUBSYNC_COMMIT" ]; then
        echo "Unexpected autosubsync-mpv commit: $staged_commit" >&2
        exit 1
    fi

    rm -rf "$autosubsync_dir"
    mv "$staging_dir" "$autosubsync_dir"
    rm -rf "$staging_root"
    trap - EXIT
fi

echo "Subtitle synchronization tools installed."
