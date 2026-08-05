#!/usr/bin/env bash

set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_root="$(cd "$scripts_dir/../../.." && pwd)"
xdg_root="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox"
legacy_root="$HOME/.mozilla/firefox"
profile_error="Firefox profile not found. Launch and close Firefox once, then rerun this script."

if [ -f "$xdg_root/profiles.ini" ]; then
    firefox_root="$xdg_root"
elif [ -f "$legacy_root/profiles.ini" ]; then
    firefox_root="$legacy_root"
else
    echo "$profile_error" >&2
    exit 1
fi

profile_path="$(awk -F= '
    /^\[Install/ { install = 1; next }
    /^\[/ { install = 0 }
    install && $1 == "Default" { print $2; exit }
' "$firefox_root/profiles.ini")"

profile="$firefox_root/$profile_path"
if [ -z "$profile_path" ] || [ ! -d "$profile" ]; then
    echo "$profile_error" >&2
    exit 1
fi

configured_source="${XDG_CONFIG_HOME:-$HOME/.config}/firefox"
if [ ! -d "$configured_source" ]; then
    echo "Firefox XDG configuration not found. Run scripts/bootstrap/link-configs.sh first." >&2
    exit 1
fi
source_root="$(readlink -f "$configured_source")"

link_config() {
    local source="$1"
    local destination="$2"
    local backup="${destination}-old"

    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        return
    fi

    if [ -L "$destination" ]; then
        case "$(readlink "$destination")" in
        "$dotfiles_root"/*)
            ln -sfn "$source" "$destination"
            return
            ;;
        esac
    fi

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            echo "Refusing to overwrite backup: $backup" >&2
            return 1
        fi
        mv -- "$destination" "$backup"
    fi

    mkdir -p "$(dirname "$destination")"
    ln -s "$source" "$destination"
}

link_config "$source_root/user.js" "$profile/user.js"
link_config "$source_root/chrome/userContent.css" "$profile/chrome/userContent.css"
