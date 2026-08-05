#!/bin/bash

set -euo pipefail

snap_block_file="${SNAP_BLOCK_FILE:-/etc/apt/preferences.d/no-snap.pref}"
firefox_archive="${FIREFOX_ARCHIVE:-/usr/lib/firefox/browser/omni.ja}"
if [ ! -f "$snap_block_file" ]; then
  echo 'Snap is not disabled. Run scripts/optional/system/disable-snap.sh first.' >&2
  exit 1
fi

if [ ! -r "$firefox_archive" ]; then

  sudo add-apt-repository -y ppa:mozillateam/ppa
  echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
  ' | sudo tee /etc/apt/preferences.d/mozilla-firefox

  sudo apt update
  sudo apt install -y firefox
else
  echo "firefox installed"
fi
