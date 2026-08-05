#!/usr/bin/env bash

set -euo pipefail

lightdm_bin="${LIGHTDM_BIN:-/usr/sbin/lightdm}"
if [ ! -x "$lightdm_bin" ]; then
  echo 'LightDM is not installed. Run this script only on Ubuntu Cinnamon with LightDM.' >&2
  exit 1
fi

if strings "$lightdm_bin" | grep -q '.xsession-errors' ; then
  sudo apt install bbe
  bbe -e 's/.xsession-errors/.cache\x2Fxs-errors/' "$lightdm_bin" > outfile
  chmod +x outfile
  sudo mv "$lightdm_bin" "${lightdm_bin}-back"
  sudo mv outfile "$lightdm_bin"
fi
