# Portable Ubuntu Bootstrap Design

## Goal

Turn this repository into an idempotent fresh-machine bootstrap for Ubuntu while keeping privileged, destructive, or machine-specific tweaks explicitly opt-in.

## Bootstrap

`scripts/setup.sh` is the single safe entry point. It:

1. verifies that it is running on Ubuntu;
2. installs the repository's ordinary `apt` packages, prompting through `sudo` normally;
3. links home and XDG configuration through the existing symlink helper; and
4. exits on failure instead of continuing with a partially configured machine.

Repeated runs must be safe. Existing user files are preserved as backups, and an existing backup is never silently overwritten.

## Optional System Changes

Scripts that remove software or modify system services, LightDM, Firefox internals, udev rules, or group membership do not run from `setup.sh`. They remain individually executable under `scripts/optional/` and are listed in the README with their effects.

## Repository Content

The repository tracks authored configuration and bootstrap code. Downloaded Anki add-ons and Yomitan dictionaries are ignored and documented as separately restorable data. Existing local files are not deleted by this change.

## Shell Configuration

The bootstrap installs `.inputrc` at the path exported by `.profile`. Zsh startup does not install software, duplicate plugin declarations, or fail merely because optional tools such as `mise` are absent.

## Documentation and Checks

The root README documents the supported Ubuntu target, bootstrap command, safe default behavior, optional scripts, and separately restored data. A small shell check verifies syntax and the bootstrap's non-destructive linking behavior without invoking `sudo` or changing the real home directory.

## Non-goals

- Supporting non-Ubuntu distributions.
- Introducing a dotfile manager, Makefile, or configuration framework.
- Automatically executing destructive system tweaks.
- Deleting the user's current downloaded data.
