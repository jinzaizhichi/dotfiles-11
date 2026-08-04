#!/bin/sh
set -u

root=${1:-.}
failed=0

rename_file() {
    source=$root/$1
    target=$root/$2
    if [ -e "$source" ]; then
        if [ -e "$target" ]; then
            printf 'Refusing to overwrite: %s\n' "$target" >&2
            failed=1
        else
            mv "$source" "$target"
            printf '%s -> %s\n' "$1" "$2"
        fi
    elif [ ! -e "$target" ]; then
        printf 'Missing source and target: %s\n' "$1" >&2
        failed=1
    fi
}

rename_file 'Season 1/Wonder Egg Priority - S01E01 - The Domain Of Children.mkv' 'Wonder Egg Priority - S01E01 - The Domain Of Children.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E02 - The Terms Of Friendship.mkv' 'Wonder Egg Priority - S01E02 - The Terms Of Friendship.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E03 - A Bare Knife.mkv' 'Wonder Egg Priority - S01E03 - A Bare Knife.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E04 - Colorful Girls.mkv' 'Wonder Egg Priority - S01E04 - Colorful Girls.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E05 - The Girl Flutist.mkv' 'Wonder Egg Priority - S01E05 - The Girl Flutist.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E06 - Punch Drunk Day.mkv' 'Wonder Egg Priority - S01E06 - Punch Drunk Day.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E07 - After School At 14.mkv' 'Wonder Egg Priority - S01E07 - After School At 14.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E08 - The Happy Friendship Plan.mkv' 'Wonder Egg Priority - S01E08 - The Happy Friendship Plan.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E09 - A Story No One Knows.mkv' 'Wonder Egg Priority - S01E09 - A Story No One Knows.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E10 - Confession.mkv' 'Wonder Egg Priority - S01E10 - Confession.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E11 - An Adult Child.mkv' 'Wonder Egg Priority - S01E11 - An Adult Child.mkv'
rename_file 'Season 1/Wonder Egg Priority - S01E12 - An Unvanquished Warrior.mkv' 'Wonder Egg Priority - S01E12 - An Unvanquished Warrior.mkv'

exit "$failed"
