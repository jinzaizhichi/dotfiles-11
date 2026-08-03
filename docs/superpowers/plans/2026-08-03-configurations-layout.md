# Configurations Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put every general declarative configuration under one descriptive `configs/` root.

**Architecture:** `configs/home` contains files linked into the home root, `configs/xdg` mirrors `$XDG_CONFIG_HOME`, `configs/system` contains files installed into system paths, and application exports such as GNOME Terminal retain their application name. Scripts remain procedural consumers of these files.

**Tech Stack:** Bash, symlinks, shell regression tests.

## Global Constraints

- Preserve existing destination paths on the installed machine.
- Do not change configuration contents or runtime behavior.
- Remove the old root-level `desktop/`, `xdg/`, and `.profile` paths.

---

### Task 1: Move declarative configuration

**Files:**
- Move: `.profile` to `configs/home/profile`
- Move: `xdg/` to `configs/xdg/`
- Move: `desktop/keyboard` to `configs/system/keyboard`
- Move: `desktop/gnome-terminal/` to `configs/gnome-terminal/`
- Modify: `tests/bootstrap.sh`
- Modify: `tests/python-environment.sh`

**Interfaces:**
- Consumes: existing tracked configuration files.
- Produces: the `configs/` hierarchy used by bootstrap scripts.

- [x] **Step 1: Change regression expectations to the new source paths**

Update link assertions and fixture paths to use `configs/home`, `configs/xdg`, `configs/system`, and `configs/gnome-terminal`.

- [x] **Step 2: Run the tests and confirm the old implementation fails**

Run: `bash tests/bootstrap.sh`

Expected: failure because the configuration files have not moved yet.

- [x] **Step 3: Move the files without changing their contents**

Create the four `configs/` responsibilities and remove the empty old roots.

- [x] **Step 4: Update every script consumer**

Change `link-configs.sh`, `configure-desktop.sh`, and Japanese setup to read from `configs/` while keeping their installed destinations unchanged.

- [x] **Step 5: Update documentation and ignore paths**

Describe `configs/` in `README.md` and move the SSH ignore rules to `configs/xdg/ssh`.

- [x] **Step 6: Verify behavior and stale-path removal**

Run: `bash tests/bootstrap.sh && git diff --check`

Expected: `All checks passed!` and no references to the removed live paths outside historical plan documents.
