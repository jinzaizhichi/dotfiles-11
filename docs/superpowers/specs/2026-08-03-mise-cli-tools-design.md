# Mise CLI Tool Ownership

Zinit manages only Zsh plugins. Mise manages `lazygit`, `lazydocker`,
`shfmt`, `k9s`, `zk`, and `shuck`; the tracked Mise configuration also
preserves the existing language versions. Mason remains responsible for
StyLua, and unused `yq` is removed.

The Ubuntu bootstrap installs the current official Mise binary into
`~/.local/bin`, links `configs/xdg/mise` to `~/.config/mise`, and runs `mise install`.
`.profile` exposes Mise's shims to every child process; no shell-specific Mise
activation is needed while the configuration contains only tools.
Tests use fake `curl` and `mise` commands so bootstrap verification never
contacts the network.
