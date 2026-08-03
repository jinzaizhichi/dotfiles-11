# Codex migration symlink repair

## Design

After moving `~/.codex` to `$XDG_DATA_HOME/codex`, repair the two stable Codex
launcher symlinks that contain absolute paths:

- `$CODEX_HOME/packages/standalone/current` continues to reference the same
  release under the new Codex home.
- `~/.local/bin/codex` references the repaired `current/bin/codex` launcher.

The migration remains one-shot and refuses to overwrite an existing target.
It does not select a release, add Codex internals to `PATH`, or add a wrapper.
A regression check creates an old absolute-link layout in a temporary home,
runs the migration with Codex processes hidden from `pgrep`, and verifies that
both links resolve under the new home.
