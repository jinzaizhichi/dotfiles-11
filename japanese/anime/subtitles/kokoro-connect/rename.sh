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

rename_file '[DB]Kokoro Connect_-_01_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 01.mkv'
rename_file '[DB]Kokoro Connect_-_02_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 02.mkv'
rename_file '[DB]Kokoro Connect_-_03_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 03.mkv'
rename_file '[DB]Kokoro Connect_-_04_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 04.mkv'
rename_file '[DB]Kokoro Connect_-_05_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 05.mkv'
rename_file '[DB]Kokoro Connect_-_06_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 06.mkv'
rename_file '[DB]Kokoro Connect_-_07_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 07.mkv'
rename_file '[DB]Kokoro Connect_-_08_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 08.mkv'
rename_file '[DB]Kokoro Connect_-_09_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 09.mkv'
rename_file '[DB]Kokoro Connect_-_10_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 10.mkv'
rename_file '[DB]Kokoro Connect_-_11_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 11.mkv'
rename_file '[DB]Kokoro Connect_-_12_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 12.mkv'
rename_file '[DB]Kokoro Connect_-_13_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 13.mkv'
rename_file '[DB]Kokoro Connect_-_14_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 14.mkv'
rename_file '[DB]Kokoro Connect_-_15_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 15.mkv'
rename_file '[DB]Kokoro Connect_-_16_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 16.mkv'
rename_file '[DB]Kokoro Connect_-_17_(Dual Audio_10bit_BD1080p_x265).mkv' 'Kokoro Connect - 17.mkv'

exit "$failed"
