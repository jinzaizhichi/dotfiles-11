# Mpvacious Note-Field Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure future mpvacious-updated notes contain one highlighted Japanese sentence and all overlapping English cues.

**Architecture:** Implement both behaviors in the existing mpvacious fork, where subtitle collection and note merging already live. Pin the dotfiles installer to the tested fork commit so local and fresh-machine installations use identical code.

**Tech Stack:** Lua, Bash, Git, AnkiConnect-compatible mpvacious configuration

## Global Constraints

- Existing Anki notes are not modified.
- Normalize only HTML markup, whitespace, and equivalent Japanese/typographic quotation marks when comparing sentences.
- Secondary cues use strict time overlap and retain subtitle order.

---

### Task 1: Prevent equivalent Japanese sentences from being appended

**Files:**
- Modify: `/tmp/mpvacious-deduplicate-secondary-lines/mpvacious/anki/note_exporter.lua`

**Interfaces:**
- Consumes: `join_field_content(new_text, old_text, { plaintext_compare = true })`
- Produces: equivalent sentence variants retain `old_text`

- [ ] Add a `pub.join_fields` regression assertion using the exact `SentKanji` variants from note `1786041864662`.
- [ ] Run `luajit tests/run.lua`; verify the assertion fails by producing a `<br>` duplicate.
- [ ] Extend plaintext normalization to collapse whitespace and canonicalize `『』「」“”` to ordinary quote markers.
- [ ] Run `luajit tests/run.lua`; verify all exporter and cue-alignment tests pass.
- [ ] Commit the fork change and record `git rev-parse HEAD` as the installer pin.

### Task 2: Pin bootstrap to the fixed fork commit

**Files:**
- Modify: `scripts/optional/japanese/setup.sh`
- Modify: `tests/bootstrap.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: the exact commit produced by Task 1
- Produces: an idempotent installation at `$XDG_CONFIG_HOME/mpv/scripts/mpvacious`

- [ ] Change the bootstrap test to expect cloning immutable tag `dotfiles-2026-08-06` from `https://github.com/kuator/mpvacious` and the exact fixed commit; verify `bash tests/bootstrap.sh` fails.
- [ ] Change `setup.sh` to clone that tag and verify `git rev-parse HEAD` equals the pinned commit; reinstall when the existing checkout is at another revision.
- [ ] Keep the upstream semantic version in `version.json`; a commit hash would trigger a false update warning. Use the exposed menu-length option rather than mutating source.
- [ ] Update README to describe the pinned fork rather than an upstream release.
- [ ] Run `bash tests/bootstrap.sh` and `git diff --check`; verify both pass.

### Task 3: Deploy and verify locally

**Files:**
- Replace generated checkout: `configs/xdg/mpv/scripts/mpvacious/` (ignored)

**Interfaces:**
- Consumes: `scripts/optional/japanese/setup.sh`
- Produces: the running mpv installation uses the pinned fixed commit after mpv restarts

- [ ] Push the fixed fork branch so fresh installs can resolve the pinned commit.
- [ ] Remove only the generated mpvacious checkout and rerun `scripts/optional/japanese/setup.sh` to install the pin.
- [ ] Verify `git -C configs/xdg/mpv/scripts/mpvacious rev-parse HEAD` equals the pin.
- [ ] Do not modify note `1786041864662`; verify it remains queryable through AnkiConnect.
