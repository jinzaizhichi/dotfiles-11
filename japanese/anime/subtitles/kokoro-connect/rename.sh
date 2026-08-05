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

rename_file 'Kokoro_Connect_TV_[01]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 01 - A Story That Had Already Begun Before Anyone Realized It.mkv'
rename_file 'Kokoro_Connect_TV_[02]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 02 - Some Fascinating Humans.mkv'
rename_file 'Kokoro_Connect_TV_[03]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 03 - Jobber and Low Blow.mkv'
rename_file 'Kokoro_Connect_TV_[04]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 04 - Twin Feelings.mkv'
rename_file 'Kokoro_Connect_TV_[05]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 05 - A Confession and Death.mkv'
rename_file 'Kokoro_Connect_TV_[06]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 06 - A Story That Continued Before Anyone Realized It.mkv'
rename_file 'Kokoro_Connect_TV_[07]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 07 - Falling Apart.mkv'
rename_file 'Kokoro_Connect_TV_[08]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 08 - And Then There Were None.mkv'
rename_file 'Kokoro_Connect_TV_[09]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 09 - Can'"'"'t Stop, Can'"'"'t Stop, Can'"'"'t Stop.mkv'
rename_file 'Kokoro_Connect_TV_[10]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 10 - Putting into Words.mkv'
rename_file 'Kokoro_Connect_TV_[11]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 11 - A Story That Began as We Realized It.mkv'
rename_file 'Kokoro_Connect_TV_[12]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 12 - Into a Snow City.mkv'
rename_file 'Kokoro_Connect_TV_[13]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' 'Kokoro Connect - 13 - As Long as the Five of Us Are Together.mkv'

exit "$failed"
