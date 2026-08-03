#!/usr/bin/env bash

set -euo pipefail

packages=(
    aria2
    bbe
    build-essential
    curl
    dirmngr
    fd-find
    ffmpeg
    fonts-noto-cjk
    fzf
    gawk
    git
    global
    gpg
    jq
    jsbeautifier
    libbz2-dev
    libffi-dev
    liblzma-dev
    libncurses-dev
    libnss3
    libreadline-dev
    libsqlite3-dev
    libssl-dev
    libxcb-cursor0
    libxcb-xinerama0
    libxml2-dev
    libxmlsec1-dev
    llvm
    make
    mpv
    pipewire
    pulseaudio-utils
    python-is-python3
    redshift-gtk
    ripgrep
    skkdic
    skkdic-extra
    ssh-askpass
    tk-dev
    trash-cli
    universal-ctags
    unzip
    webp
    wget
    xcape
    xclip
    xz-utils
    zathura
    zlib1g-dev
    zoxide
    zsh
    zstd
)

sudo apt-get update
sudo apt-get install -y "${packages[@]}"
