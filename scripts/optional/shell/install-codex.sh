#!/usr/bin/env bash

set -euo pipefail

source_dir="$HOME/.codex"
target_dir="${XDG_DATA_HOME:-$HOME/.local/share}/codex"
launcher="$HOME/.local/bin/codex"
mise_bin="$HOME/.local/bin/mise"

if pgrep -u "$(id -u)" -x codex >/dev/null 2>&1; then
	echo 'Close every Codex process before installing or updating Codex.' >&2
	exit 1
fi

if [ ! -x "$mise_bin" ]; then
	echo 'Mise is not installed. Run scripts/setup.sh first.' >&2
	exit 1
fi

if [ -e "$source_dir" ]; then
	if [ -e "$target_dir" ]; then
		echo "Refusing to overwrite existing destination: $target_dir" >&2
		exit 1
	fi

	mkdir -p "$(dirname "$target_dir")"
	mv -- "$source_dir" "$target_dir"
else
	mkdir -p "$target_dir"
fi

export CODEX_HOME="$target_dir"
"$mise_bin" exec -- npm install --global @openai/codex@latest
"$mise_bin" reshim

if [ -L "$launcher" ]; then
	case "$(readlink "$launcher")" in
	"$source_dir"/* | "$target_dir"/*) rm -- "$launcher" ;;
	esac
fi

echo "Codex is installed with its data in $target_dir."
