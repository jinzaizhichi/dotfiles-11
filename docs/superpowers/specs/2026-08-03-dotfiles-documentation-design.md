# Dotfiles Documentation Design

## Goal

Make `README.md` the single place to understand this repository and rebuild the
owner's Ubuntu machine in the correct order.

## Audience and scope

The README is a personal recovery runbook, not a generic dotfiles tutorial. It
documents repository-owned configuration, data, entry points, optional setup,
wrappers, and tests. It does not catalog the internals of downloaded Anki
add-ons, dictionary archives, or the vendored mpvacious checkout.

## Structure

The README starts with an ordered fresh-install checklist, because that is the
time when missing prerequisites and ordering mistakes are most expensive. It
then provides a concise repository map organized by responsibility rather than
an exhaustive file listing.

The fresh-install checklist has these phases:

1. Install Ubuntu prerequisites, clone the repository, and run
   `scripts/setup.sh`.
2. Apply machine-level and login configuration: disable Snap before installing
   Firefox, configure the login shell, Bash fallback, Kanata, SSH, sudo marker,
   and desktop-specific LightDM changes when LightDM is still in use.
3. Log out or reboot so group membership, login-shell environment, keyboard,
   and display-manager changes take effect.
4. Install and configure desktop applications in dependency order: fonts and
   terminal profile; Firefox installation, first launch, profile links,
   keybinding patch, and new-tab service; Appgate installation followed by its
   system wrapper; Codex installation followed by migration while Codex is
   closed.
5. Set up Japanese study tools: install Anki and mpvacious, install the printed
   AnkiWeb add-on codes, restart Anki, restore optional local audio, download and
   import Yomitan dictionaries/settings, and update the Japanese Sentences note
   type while AnkiConnect is running.
6. Run the test suite and perform a short verification checklist.

Commands that are conditional or destructive state that directly beside the
command. Manual application steps are explicit; the README does not imply that
the bootstrap can configure browser extensions, import Yomitan dictionaries,
or install AnkiWeb add-ons automatically.

## Repository map

The map uses six role labels:

- **Configuration/data**: `.profile`, `configs/xdg/`, `desktop/`, and manifests/assets
  under `japanese/`.
- **Automatic bootstrap**: `scripts/setup.sh` and internal helpers under
  `scripts/bootstrap/`.
- **Manual setup**: scripts under `scripts/optional/`, grouped by desktop,
  Firefox, Japanese study, shell, and system responsibility.
- **Wrapper**: commands under `bin/` linked into `~/.local/bin`.
- **Test**: the checks under `tests/`.
- **Downloaded/vendor content**: ignored Anki add-ons, downloaded dictionaries,
  and the mpvacious checkout, described only at directory level.

Every manual setup script gets a one-line purpose. Ordinary XDG files are
grouped by application; special data files such as `configs/system/keyboard`, the Anki
add-on manifest, Yomitan settings and dictionary manifest, and the new-tab
assets are named individually where their role is not obvious.

## Maintenance rules

- New automatic behavior must be added to the fresh-install phase that invokes
  it and to the repository map.
- New manual scripts must be added to the relevant optional-script table.
- Generated or downloaded internals are never expanded into per-file README
  entries.
- Detailed application-specific instructions stay in their existing section or
  application README and are linked from the runbook rather than duplicated.

## Verification

The documentation test checks that the README names the bootstrap entry point,
all current optional scripts, the six primary repository roles, and the full
test command. Existing repository tests continue to verify that referenced
scripts exist and are executable.
