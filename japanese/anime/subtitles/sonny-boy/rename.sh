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

rename_file 'Season 1/Sonny Boy - S01E01 - The Island At The Far End Of Summer.mkv' 'Sonny Boy - 01 - The Island At The Far End Of Summer.mkv'
rename_file 'Season 1/Sonny Boy - S01E02 - Aliens.mkv' 'Sonny Boy - 02 - Aliens.mkv'
rename_file 'Season 1/Sonny Boy - S01E03 - The Cat Who Wore Sandals.mkv' 'Sonny Boy - 03 - The Cat Who Wore Sandals.mkv'
rename_file 'Season 1/Sonny Boy - S01E04 - The Great Monkey Baseball.mkv' 'Sonny Boy - 04 - The Great Monkey Baseball.mkv'
rename_file 'Season 1/Sonny Boy - S01E05 - Leaping Classrooms.mkv' 'Sonny Boy - 05 - Leaping Classrooms.mkv'
rename_file 'Season 1/Sonny Boy - S01E06 - The Long Goodbye.mkv' 'Sonny Boy - 06 - The Long Goodbye.mkv'
rename_file 'Season 1/Sonny Boy - S01E07 - Road Book.mkv' 'Sonny Boy - 07 - Road Book.mkv'
rename_file 'Season 1/Sonny Boy - S01E08 - Laughing Dog.mkv' 'Sonny Boy - 08 - Laughing Dog.mkv'
rename_file 'Season 1/Sonny Boy - S01E09 - This Salmon Chazuke Is Missing Its Salmon Nya.mkv' 'Sonny Boy - 09 - This Salmon Chazuke Is Missing Its Salmon Nya.mkv'
rename_file 'Season 1/Sonny Boy - S01E10 - Summer And The Demon.mkv' 'Sonny Boy - 10 - Summer And The Demon.mkv'
rename_file 'Season 1/Sonny Boy - S01E11 - The Young Man And The Sea.mkv' 'Sonny Boy - 11 - The Young Man And The Sea.mkv'
rename_file 'Season 1/Sonny Boy - S01E12 - A Two-Year Recess.mkv' 'Sonny Boy - 12 - A Two-Year Recess.mkv'

exit "$failed"
