#!/bin/bash

set -euo pipefail

lightdm_bin="${LIGHTDM_BIN:-/usr/sbin/lightdm}"
if [ ! -x "$lightdm_bin" ]; then
  echo 'LightDM is not installed. Run this script only on Ubuntu Cinnamon with LightDM.' >&2
  exit 1
fi

if [ ! -f /etc/lightdm/lightdm.conf ]; then
  echo '[LightDM]
user-authority-in-system-dir=true
' | sudo tee -a /etc/lightdm/lightdm.conf
elif ! grep -q 'user-authority-in-system-dir=true' "/etc/lightdm/lightdm.conf"; then
  echo '[LightDM]
user-authority-in-system-dir=true' | sudo tee -a /etc/lightdm/lightdm.conf
fi
