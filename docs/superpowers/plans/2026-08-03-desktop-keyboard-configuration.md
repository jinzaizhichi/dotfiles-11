# Desktop Keyboard Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure equivalent native keyboard settings on Cinnamon and KDE Plasma through one auto-detecting bootstrap script.

**Architecture:** `configure-desktop.sh` dispatches on `XDG_CURRENT_DESKTOP`. Its two small functions use GSettings for Cinnamon and KConfig command-line tools for Plasma.

**Tech Stack:** Bash, GSettings, `kwriteconfig6`/`kwriteconfig5`, shell bootstrap checks

## Global Constraints

- Configure `us,ru` layouts and `grp:alt_shift_toggle`.
- Configure a 220 ms delay and 40 repeats per second.
- Do nothing for unknown desktops.
- Do not install KDE or link entire KDE configuration files.

---

### Task 1: Add desktop-aware native keyboard configuration

**Files:**
- Create: `scripts/bootstrap/configure-desktop.sh`
- Delete: `scripts/bootstrap/configure-cinnamon.sh`
- Modify: `scripts/setup.sh`
- Modify: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: `XDG_CURRENT_DESKTOP`, GSettings, and an available KConfig writer.
- Produces: native keyboard layout and repeat settings for Cinnamon or Plasma.

- [x] **Step 1: Write failing checks**

Make setup explicitly exercise `X-Cinnamon`; add a fake `kwriteconfig6` and a
separate `KDE` invocation. Assert the native Cinnamon calls, Plasma writes to
`kxkbrc` and `kcminputrc`, no calls for an unknown desktop, and the renamed
script inventory.

- [x] **Step 2: Verify the checks fail**

Run `./tests/bootstrap.sh`; expect failure because
`scripts/bootstrap/configure-desktop.sh` does not exist.

- [x] **Step 3: Implement the dispatcher**

Create `configure-desktop.sh` with `configure_cinnamon` and `configure_kde`
functions, dispatch with a shell `case`, update `scripts/setup.sh`, and delete
the old Cinnamon-only script.

- [x] **Step 4: Verify the implementation**

Run:

```sh
./tests/bootstrap.sh
sh -n scripts/bootstrap/configure-desktop.sh scripts/setup.sh
shfmt -d scripts/bootstrap/configure-desktop.sh scripts/setup.sh
git diff --check
```

Expected: all commands exit successfully.
