#!/bin/bash

set -euo pipefail

if sudo --version 2>/dev/null | head -n 1 | grep -qi 'sudo-rs'; then
  echo 'sudo-rs does not create ~/.sudo_as_admin_successful; nothing to configure.'
  exit 0
fi

disable_admin_file_in_home="${SUDO_ADMIN_FLAG_FILE:-/etc/sudoers.d/disable_admin_file_in_home}"
bashrc="${BASHRC_FILE:-/etc/bash.bashrc}"

if [ ! -f "$disable_admin_file_in_home" ]; then
  echo '
# Disable ~/.sudo_as_admin_successful file
Defaults !admin_flag
  ' | sudo tee "$disable_admin_file_in_home"

fi

if grep -q 'sudo_as_admin_successful' "$bashrc"; then
  sudo vi -E -s "$bashrc" << EOF
:%s/\v^\#.{-}sudo.{-}hint\_.{-}sudo_root\_.{-}^fi
:update
:quit
EOF

fi
