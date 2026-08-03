#!/usr/bin/env bash

set -euo pipefail

mise_bin="$HOME/.local/bin/mise"

curl --fail --silent --show-error --location https://mise.run |
    MISE_INSTALL_PATH="$mise_bin" MISE_INSTALL_SKIP_IF_EXISTS=1 sh

"$mise_bin" install --yes \
    rust uv lazygit lazydocker shfmt k9s github:zk-org/zk github:ewhauser/shuck bob \
    github:jtroo/kanata

"$mise_bin" exec -- bob use nightly
