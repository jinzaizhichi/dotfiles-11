#!/usr/bin/env bash

set -euo pipefail

snap_data="$HOME/snap"
snap_backup="$HOME/.snap-before-disable"

restore_snap_data() {
    [ -e "$snap_backup" ] || return 0

    if [ -e "$snap_data" ]; then
        echo "Could not restore $snap_data; its original contents remain at $snap_backup." >&2
        return 1
    fi

    mv -- "$snap_backup" "$snap_data"
}

if [ -e "$snap_data" ]; then
    if [ -e "$snap_backup" ]; then
        echo "Refusing to overwrite existing backup: $snap_backup" >&2
        exit 1
    fi

    mv -- "$snap_data" "$snap_backup"
    trap restore_snap_data EXIT
fi

remove_snaps() {
    local kind="$1"
    local removed
    local name
    local -a names

    while true; do
        mapfile -t names < <(snap list | awk -v kind="$kind" '
            NR > 1 && kind == "apps" && $NF != "base" && $NF != "snapd" { print $1 }
            NR > 1 && $NF == kind { print $1 }
        ')
        ((${#names[@]})) || return 0

        removed=0
        for name in "${names[@]}"; do
            if sudo snap remove --purge "$name"; then
                removed=$((removed + 1))
            fi
        done

        if ((removed == 0)); then
            printf 'Could not remove remaining %s snaps: %s\n' "$kind" "${names[*]}" >&2
            return 1
        fi
    done
}

if command -v snap >/dev/null 2>&1; then
    remove_snaps apps
    remove_snaps base
    remove_snaps snapd
fi

sudo apt-get purge -y snapd

cat <<'EOF' | sudo tee /etc/apt/preferences.d/no-snap.pref >/dev/null
Package: snapd
Pin: version *
Pin-Priority: -10
EOF

restore_snap_data
trap - EXIT

echo 'Snap is disabled. Existing user data under $HOME/snap was preserved.'
