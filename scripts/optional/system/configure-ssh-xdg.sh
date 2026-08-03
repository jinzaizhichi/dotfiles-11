#!/usr/bin/env bash

set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config="$config_home/ssh/config"
known_hosts="$config_home/ssh/known_hosts"
legacy_dir="$HOME/.ssh"
system_config=/etc/ssh/ssh_config.d/00-xdg.conf
system_include="Include \"$config\""

if [ ! -f "$config" ]; then
    echo "SSH configuration not found: $config" >&2
    exit 1
fi

if [ -d "$legacy_dir" ] && find "$legacy_dir" -mindepth 1 -maxdepth 1 \
    ! -name known_hosts ! -name known_hosts.old -print -quit | grep -q .; then
    echo "Refusing to remove $legacy_dir because it contains files other than known_hosts backups." >&2
    exit 1
fi

if ! grep -Fqx "$system_include" "$system_config" 2>/dev/null; then
    printf '%s\n' "$system_include" | sudo tee "$system_config" >/dev/null
fi

if [ -f "$legacy_dir/known_hosts" ]; then
    mkdir -p "$(dirname "$known_hosts")"
    touch "$known_hosts"
    merged="$(mktemp "${known_hosts}.XXXXXX")"
    trap 'rm -f "$merged"' EXIT
    awk 'NF && !seen[$0]++' "$known_hosts" "$legacy_dir/known_hosts" >"$merged"
    chmod 600 "$merged"
    mv -- "$merged" "$known_hosts"
    trap - EXIT
fi

if ! ssh -G xdg.invalid 2>/dev/null |
    grep -Fqx "userknownhostsfile $known_hosts"; then
    echo "OpenSSH did not load $config through $system_config." >&2
    exit 1
fi

if [ -d "$legacy_dir" ]; then
    rm -f -- "$legacy_dir/known_hosts" "$legacy_dir/known_hosts.old"
    rmdir -- "$legacy_dir"
fi

echo "OpenSSH now uses $config for every client invocation."
