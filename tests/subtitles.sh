#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
subtitles="$root/japanese/anime/subtitles"

if find "$subtitles" -type d -name subs.jp -print -quit | grep -q .; then
    echo 'Japanese subtitle directories must be named subs.ja' >&2
    exit 1
fi

if rg -n '^Comment:' "$subtitles" -g '*.ass'; then
    echo 'ASS comments must not be shipped in mining subtitles' >&2
    exit 1
fi

if rg -n '\{\\(?:an|pos|move|clip|p)[^}]*\}' "$subtitles" -g '*.ass' -g '*.srt'; then
    echo 'Positioning and drawing overrides must not be shipped in mining subtitles' >&2
    exit 1
fi

if rg -n 'ダウンロードされた|このひろい大空に|今わたしが出来ることは' \
    "$subtitles/sonny-boy" -g '*.srt'; then
    echo 'Known Sonny Boy song lyrics must not be shipped in mining subtitles' >&2
    exit 1
fi

test "$(find "$subtitles" -type f \( -name '*.ass' -o -name '*.srt' \) | wc -l)" -ge 232
