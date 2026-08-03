# Ubuntu Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository safely bootstrap a fresh Ubuntu installation with one command while keeping destructive and machine-specific operations opt-in.

**Architecture:** `scripts/setup.sh` orchestrates ordinary package installation and the existing symlink installer. All privileged system tweaks remain standalone under `scripts/optional/`; shell startup only loads already-installed tools.

**Tech Stack:** Bash, Zsh, apt-get, Git

## Global Constraints

- Support Ubuntu only.
- Preserve existing files and never overwrite an existing backup.
- Do not execute optional system tweaks from the main bootstrap.
- Add no dependency or dotfile framework.
- Do not delete local Anki or Yomitan downloads.

---

### Task 1: Non-destructive configuration installer

**Files:**
- Create: `tests/bootstrap.sh`
- Move: `.inputrc` to `configs/xdg/readline/inputrc`
- Modify: `scripts/link-configs.sh`

**Interfaces:**
- Consumes: `HOME`, optional `XDG_CONFIG_HOME`, and the repository path derived from the script location.
- Produces: symlinks for `.profile`, `.xprofile`, `~/.config/*`, and `~/.local/bin`.

- [ ] **Step 1: Write the failing behavior check**

```bash
#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home" "$tmp/config/nvim"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
  "$repo/scripts/link-configs.sh"
test "$(readlink "$tmp/config/readline")" = "$repo/configs/xdg/readline"
test "$(readlink "$tmp/home/.local/bin")" = "$repo/bin"
```

- [ ] **Step 2: Run it and verify failure because `configs/xdg/readline` is absent**

Run: `bash tests/bootstrap.sh`
Expected: FAIL at the readline assertion.

- [ ] **Step 3: Implement the minimum safe linker**

Derive `DOTFILES` from `BASH_SOURCE`, create parent directories, link the relocated readline configuration, and refuse to overwrite `<destination>-old`.

- [ ] **Step 4: Run the check**

Run: `bash tests/bootstrap.sh`
Expected: PASS.

### Task 2: Safe Ubuntu entry point and optional boundary

**Files:**
- Modify: `scripts/setup.sh`
- Modify: `scripts/install-packages.sh`
- Move: system-changing and machine-specific scripts to `scripts/optional/`
- Modify: `configs/xdg/zsh/.zshrc`

**Interfaces:**
- Consumes: Ubuntu `/etc/os-release`, ordinary sudo authentication, and network access.
- Produces: installed apt packages, Zinit under XDG data, and linked configuration.

- [ ] **Step 1: Extend the failing check**

Add `bash -n` over all Bash scripts and `zsh -n configs/xdg/zsh/.zshrc`; this catches broken orchestration or moves.

- [ ] **Step 2: Simplify package installation**

Replace per-package probing with one idempotent call:

```bash
sudo apt-get update
sudo apt-get install -y "${packages[@]}"
```

- [ ] **Step 3: Implement the entry point**

Have `setup.sh` reject non-Ubuntu systems, call the two safe scripts by absolute repository path, and install Zinit outside shell startup when missing.

- [ ] **Step 4: Move optional scripts and simplify Zsh startup**

Move all scripts except `setup.sh`, `install-packages.sh`, and `link-configs.sh` under `scripts/optional/`. Remove Zinit's startup-time clone, the duplicate fzf declaration, and guard `mise` with `command -v`.

- [ ] **Step 5: Run the check**

Run: `bash tests/bootstrap.sh`
Expected: PASS with clean shell syntax.

### Task 3: Repository hygiene and documentation

**Files:**
- Create: `README.md`
- Modify: `.gitignore`
- Untrack while preserving locally: `japanese/anki/addons21/`, `japanese/yomitan/dictionaries/`

**Interfaces:**
- Produces: documented bootstrap and opt-in commands; downloaded payloads remain local but leave the Git index.

- [ ] **Step 1: Ignore downloaded payloads**

Add:

```gitignore
/japanese/anki/addons21/
/japanese/yomitan/dictionaries/
```

Then use `git rm --cached` so files remain on disk.

- [ ] **Step 2: Document the workflow**

Document `./scripts/setup.sh`, its sudo/package behavior, the optional-script directory, and manual restoration of Anki/Yomitan data.

- [ ] **Step 3: Verify the whole change**

Run: `bash tests/bootstrap.sh`, `shellcheck -S warning scripts/*.sh scripts/optional/*.sh tests/bootstrap.sh`, and `git diff --check`.
Expected: all checks pass with no warnings from maintained shell scripts.

### Task 4: Organize and clarify script names

**Files:**
- Keep: `scripts/install-packages.sh`
- Keep: `scripts/link-configs.sh`
- Organize: Firefox scripts under `scripts/optional/firefox/`
- Organize: LightDM scripts under `scripts/optional/lightdm/`
- Rename: remaining optional scripts by their outcome
- Modify: `scripts/optional/disable-snap.sh`
- Modify: `scripts/setup.sh`, `tests/bootstrap.sh`, `README.md`

**Interfaces:**
- Consumes: the same command-line invocation and environment variables as the existing scripts.
- Produces: shallow domain folders, outcome-based names, and Ubuntu-version-independent Snap removal.

- [ ] **Step 1: Update the bootstrap check for the new paths and Snap behavior**

Assert that every documented script exists and is executable. Run `disable-snap.sh` with fake `snap` and `sudo` commands, then verify that installed application, base, and snapd snaps are removed in dependency order, `snapd` is purged, and an APT pin is written.

- [ ] **Step 2: Run the check and verify the old structure fails**

Run: `bash tests/bootstrap.sh`
Expected: FAIL because `scripts/link-configs.sh` does not exist.

- [ ] **Step 3: Apply the shallow organization**

Keep `setup.sh`, `install-packages.sh`, and `link-configs.sh` at the top level. Create only `optional/firefox/` and `optional/lightdm/`; rename other optional scripts without adding generic grouping folders.

- [ ] **Step 4: Make Snap removal version-independent and non-destructive to home data**

Discover installed snaps with `snap list`, remove ordinary snaps before base snaps and `snapd`, purge the deb package, and pin `snapd` to priority `-10`. Do not delete `$HOME/snap` or other user data.

- [ ] **Step 5: Update callers and documentation**

Update `setup.sh`, the bootstrap check, and README paths and descriptions.

- [ ] **Step 6: Verify the whole change**

Run: `bash tests/bootstrap.sh`, `shellcheck -S warning scripts/*.sh scripts/optional/*.sh scripts/optional/firefox/*.sh scripts/optional/lightdm/*.sh tests/bootstrap.sh`, `git diff --check`, and `git diff --cached --check`.
Expected: all checks pass.
