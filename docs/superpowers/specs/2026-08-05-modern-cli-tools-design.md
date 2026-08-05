# Modern CLI Tools Design

## Goal

Make `bat`, `eza`, `delta`, and `bottom` reproducible on fresh machines without replacing standard Unix commands.

## Design

- Mise installs and updates all four tools alongside the existing user-level CLI tools.
- `bat`, `eza`, and `btm` remain explicit commands; no `cat`, `ls`, or `top` aliases are added.
- Git uses Delta as its pager and interactive diff filter. Existing Neovim diff and merge tools remain unchanged.
- The bootstrap test verifies that the tools are declared and passed to Mise, and that Git contains the Delta integration.

## Verification

- Run the bootstrap test suite.
- Confirm all four executables run on the current machine.
- Confirm `git diff` invokes Delta in an interactive terminal.
