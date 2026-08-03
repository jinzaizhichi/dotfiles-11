#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
manifest="$repo/japanese/yomitan/dictionaries.txt"
destination="$repo/japanese/yomitan/dictionaries"

mkdir -p "$destination"

is_dictionary() {
    unzip -Z1 "$1" | awk '$0 == "index.json" { found = 1 } END { exit !found }'
}

while IFS=$'\t' read -r source filename; do
    [ -n "$source" ] || continue
    case "$source" in \#*) continue ;; esac

    case "$source" in
        https://*) url="$source" ;;
        *) url="https://drive.usercontent.google.com/download?id=$source&export=download&confirm=t" ;;
    esac

    target="$destination/$filename"
    if [ -f "$target" ]; then
        if ! is_dictionary "$target"; then
            echo "Existing file is not a Yomitan dictionary: $filename" >&2
            exit 1
        fi
        echo "Already downloaded: $filename"
        continue
    fi

    echo "Downloading: $filename"
    curl --fail --location --retry 3 --retry-all-errors --continue-at - \
        --output "$target.part" \
        "$url"

    if ! is_dictionary "$target.part"; then
        echo "Downloaded file is not a Yomitan dictionary: $filename" >&2
        exit 1
    fi

    mv "$target.part" "$target"
done <"$manifest"
