#!/usr/bin/env bash

set -euo pipefail

MINIMIZE2TRAY_REPO="https://github.com/luisbocanegra/kwin-minimize2tray.git"
MINIMIZE2TRAY_COMMIT="f5e8d140a6660324cafa2188350c858134c80ab2"

case "${XDG_CURRENT_DESKTOP:-}" in
*Cinnamon*)
	repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
	install_dir="$HOME/.local/libexec/dotfiles"
	staging_binary="$(mktemp)"
	trap 'rm -f "$staging_binary"' EXIT
	"${CC:-cc}" -O2 -Wall -Wextra -Werror \
		"$repo/src/x11-close-to-tray.c" -lX11 -o "$staging_binary"
	mkdir -p "$install_dir"
	install -m 755 "$staging_binary" "$install_dir/x11-close-to-tray"
	echo "Installed KDocker close-to-tray helper."
	exit 0
	;;
*KDE*) ;;
*)
	echo "No supported window-to-tray integration for this desktop."
	exit 0
	;;
esac

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$XDG_DATA_HOME/dotfiles"
marker="$state_dir/kwin-minimize2tray.commit"

if [ -f "$marker" ] && [ "$(cat "$marker")" = "$MINIMIZE2TRAY_COMMIT" ]; then
	echo "KWin Minimize2Tray $MINIMIZE2TRAY_COMMIT already installed."
	exit 0
fi

staging_root="$(mktemp -d)"
checkout_dir="$staging_root/kwin-minimize2tray"
cleanup() {
	rm -rf "$staging_root"
}
trap cleanup EXIT

git clone --no-checkout "$MINIMIZE2TRAY_REPO" "$checkout_dir"
git -C "$checkout_dir" checkout --detach "$MINIMIZE2TRAY_COMMIT"

installed_commit="$(git -C "$checkout_dir" rev-parse HEAD)"
if [ "$installed_commit" != "$MINIMIZE2TRAY_COMMIT" ]; then
	echo "Unexpected KWin Minimize2Tray commit: $installed_commit" >&2
	exit 1
fi

cmake -B "$checkout_dir/build/script" -S "$checkout_dir" \
	-DBUILD_PLUGIN=OFF -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build "$checkout_dir/build/script"
cmake --install "$checkout_dir/build/script"

cmake -B "$checkout_dir/build/plugin" -S "$checkout_dir" \
	-DINSTALL_SCRIPT=OFF -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$checkout_dir/build/plugin"
sudo cmake --install "$checkout_dir/build/plugin"

mkdir -p "$state_dir"
printf '%s\n' "$MINIMIZE2TRAY_COMMIT" >"$marker"

echo "Installed KWin Minimize2Tray $MINIMIZE2TRAY_COMMIT."
echo "Log out and back in before using Meta+Alt+PgDown."
