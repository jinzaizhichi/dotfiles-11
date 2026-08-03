# Dotfiles Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `README.md` into the authoritative ordered fresh-machine runbook and concise responsibility map for this personal Ubuntu repository.

**Architecture:** Keep one documentation entry point. The README leads with execution order, then explains repository-owned configuration/data, automatic bootstrap helpers, manual setup scripts, wrappers, tests, and downloaded/vendor content without cataloging third-party internals.

**Tech Stack:** Markdown and the existing Bash test harness

## Global Constraints

- `README.md` remains the single operational documentation entry point.
- Every current script under `scripts/optional/` receives a one-line purpose.
- Ordinary XDG files are grouped by application rather than listed exhaustively.
- Downloaded Anki add-ons, dictionary archive contents, and mpvacious internals are documented only at directory level.
- Commands that require a reboot, a running application, a closed application, sudo, or manual GUI work say so beside the command.

---

### Task 1: Document the rebuild workflow and repository responsibilities

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: the existing `expected_scripts` array in `tests/bootstrap.sh` and current paths under `scripts/`, `bin/`, `desktop/`, `configs/xdg/`, `japanese/`, and `tests/`.
- Produces: one README whose commands and paths correspond to files checked by the repository test suite.

- [ ] **Step 1: Add failing documentation coverage checks**

After the existing executable check for each `expected_scripts` entry, require every optional script's relative path to occur in `README.md`:

```bash
case "$script" in
scripts/optional/*)
    grep -Fq "\`${script#scripts/optional/}\`" "$repo/README.md"
    ;;
esac
```

Also assert that the README contains the headings `## Fresh-machine runbook`, `## Repository map`, the six role labels `Configuration/data`, `Automatic bootstrap`, `Manual setup`, `Wrapper`, `Test`, and `Downloaded/vendor content`, plus the command `./tests/bootstrap.sh`.

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash tests/bootstrap.sh`

Expected: FAIL because the current README lacks the fresh-machine heading, role labels, and `system/configure-appgate-xdg.sh` entry.

- [ ] **Step 3: Rewrite the README**

Preserve the Ubuntu 24.04 scope and clone command. Replace the current install-first organization with these sections:

```text
# Dotfiles
## Fresh-machine runbook
### 1. Clone and bootstrap
### 2. Configure the operating system and login
### 3. Log out or reboot
### 4. Configure desktop applications
### 5. Restore Japanese study tools
### 6. Verify the machine
## Repository map
### Configuration/data
### Automatic bootstrap
### Manual setup
### Wrapper
### Test
### Downloaded/vendor content
## Maintenance rule
```

The runbook must encode these dependencies:

- Run `scripts/setup.sh` before every optional script.
- Run `system/disable-snap.sh` before `firefox/install.sh`.
- Run shell/system migrations, then log out or reboot for group membership, login shell, keyboard, and LightDM changes.
- Install the Nerd Font before importing the GNOME Terminal profile.
- Launch Firefox once and close it before profile linking and `omni.ja` patching; configure browser extensions manually after enabling the new-tab service.
- Install Appgate's Debian package before `system/configure-appgate-xdg.sh`.
- Close Codex before `shell/migrate-codex-home.sh`.
- Run `japanese/setup.sh`, install its printed AnkiWeb codes, restart Anki, then restore audio.
- Download/import Yomitan dictionaries and settings manually.
- Keep Anki running with AnkiConnect before `japanese/update-japanese-sentences.sh`, then restart Anki.
- Treat both LightDM scripts as conditional on still using LightDM.

The repository map must explain `.profile`, `configs/xdg/`, `configs/system/keyboard`, `configs/gnome-terminal/profile.dconf`, the Japanese manifests/settings/assets, all bootstrap and optional script groups, each `bin/` wrapper, the test files, ignored Anki add-ons, dictionary archives, and the mpvacious checkout at directory granularity.

- [ ] **Step 4: Run verification**

Run: `bash tests/bootstrap.sh`

Expected: PASS with `All checks passed!` and no missing README path.

- [ ] **Step 5: Check links and command references**

Run:

```bash
rg -o '`[^`]+[.](sh|js|json|dconf|toml)`' README.md
find scripts bin tests -type f -not -path '*/.git/*' -print
```

Expected: every documented repository command resolves to a current file and generated/vendor internals are not expanded into a file-by-file catalog.
