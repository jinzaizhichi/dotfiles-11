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

rename_file '[Judas] Erased - 01.mkv' 'Erased - 01.mkv'
rename_file '[Judas] Erased - 02.mkv' 'Erased - 02.mkv'
rename_file '[Judas] Erased - 03.mkv' 'Erased - 03.mkv'
rename_file '[Judas] Erased - 04.mkv' 'Erased - 04.mkv'
rename_file '[Judas] Erased - 05.mkv' 'Erased - 05.mkv'
rename_file '[Judas] Erased - 06.mkv' 'Erased - 06.mkv'
rename_file '[Judas] Erased - 07.mkv' 'Erased - 07.mkv'
rename_file '[Judas] Erased - 08.mkv' 'Erased - 08.mkv'
rename_file '[Judas] Erased - 09.mkv' 'Erased - 09.mkv'
rename_file '[Judas] Erased - 10.mkv' 'Erased - 10.mkv'
rename_file '[Judas] Erased - 11.mkv' 'Erased - 11.mkv'
rename_file '[Judas] Erased - 12.mkv' 'Erased - 12.mkv'

exit "$failed"
