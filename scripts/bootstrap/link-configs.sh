#!/usr/bin/env bash

set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$scripts_dir/../.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

symlink_configuration() {
	local source="$1"
	local destination="$2"
	local backup="${destination}-old"

	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
		echo "Symlink exists: $destination"
		return
	fi

	if [ -L "$destination" ] && [ ! -e "$destination" ]; then
		case "$(readlink "$destination")" in
		"$DOTFILES"/*)
			ln -sfn "$source" "$destination"
			echo "Updated moved symlink: $destination"
			return
			;;
		esac
	fi

	if [ -e "$destination" ] || [ -L "$destination" ]; then
		if [ -e "$backup" ] || [ -L "$backup" ]; then
			echo "Refusing to overwrite backup: $backup" >&2
			return 1
		fi

		echo "Backing up existing path: $destination"
		mv -- "$destination" "$backup"
	fi

	mkdir -p "$(dirname "$destination")"
	ln -sv "$source" "$destination"
}

if [ ! -d "$XDG_CONFIG_HOME/nvim" ]; then
	git clone https://github.com/kuator/nvim.git "$XDG_CONFIG_HOME/nvim"
fi

symlink_configuration "$DOTFILES/configs/home/profile" "$HOME/.profile"

shopt -s nullglob dotglob
for path in "$DOTFILES/configs/xdg"/*; do
	case "$(basename "$path")" in
	codium | ty) continue ;;
	esac
	symlink_configuration "$path" "$XDG_CONFIG_HOME/$(basename "$path")"
done

for service in kanata new-tab xm6-audio-guard; do
	symlink_configuration \
		"$DOTFILES/configs/xdg/$service/$service.service" \
		"$XDG_CONFIG_HOME/systemd/user/$service.service"
done

symlink_configuration "$DOTFILES/configs/xdg/ty/ty.toml" "$XDG_CONFIG_HOME/ty/ty.toml"

for configuration in settings.json keybindings.json; do
	symlink_configuration \
		"$DOTFILES/configs/xdg/codium/$configuration" \
		"$XDG_CONFIG_HOME/VSCodium/User/$configuration"
done

mkdir -p "$HOME/.local/bin"
for command in "$DOTFILES/bin"/*; do
	symlink_configuration "$command" "$HOME/.local/bin/$(basename "$command")"
done

if [ -f /usr/share/applications/codium.desktop ]; then
	mkdir -p "$XDG_DATA_HOME/applications"
	sed 's#^Exec=/usr/share/codium/codium#Exec=codium#' \
		/usr/share/applications/codium.desktop \
		>"$XDG_DATA_HOME/applications/codium.desktop"
fi
