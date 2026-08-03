# Native Keyboard Repeat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `.xprofile` `xset` command with equivalent native Cinnamon keyboard-repeat settings.

**Architecture:** The existing Cinnamon bootstrap owns desktop keyboard configuration. It will set a 220 ms repeat delay and 25 ms repeat interval; the generic linker will no longer install `.xprofile`.

**Tech Stack:** Bash, GSettings, shell bootstrap checks

## Global Constraints

- Preserve the effective `xset r rate 220 40` behavior.
- Do not add an autostart entry, Xorg configuration, or dependency.
- Remove `.xprofile` because it has no remaining purpose.

---

### Task 1: Move keyboard repeat configuration into Cinnamon

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `scripts/bootstrap/configure-cinnamon.sh`
- Modify: `scripts/bootstrap/link-configs.sh`
- Delete: `.xprofile`

**Interfaces:**
- Consumes: Cinnamon GSettings schemas and the existing bootstrap flow.
- Produces: native 220 ms delay and 25 ms repeat interval without `.xprofile`.

- [x] **Step 1: Write the failing bootstrap checks**

Make the fake GSettings command expose both required schemas, assert these calls:

```text
set org.cinnamon.desktop.peripherals.keyboard delay 220
set org.cinnamon.desktop.peripherals.keyboard repeat-interval 25
```

Also assert that setup does not create `$HOME/.xprofile`.

- [x] **Step 2: Run the check and verify it fails**

Run: `./tests/bootstrap.sh`

Expected: failure because the repeat settings are absent and `.xprofile` is still linked.

- [x] **Step 3: Implement the native settings**

Add the two GSettings writes to `configure-cinnamon.sh`, remove `.xprofile` from `link-configs.sh`, and delete `.xprofile`.

- [x] **Step 4: Run verification**

Run:

```sh
./tests/bootstrap.sh
sh -n scripts/bootstrap/configure-cinnamon.sh scripts/bootstrap/link-configs.sh
shfmt -d scripts/bootstrap/configure-cinnamon.sh scripts/bootstrap/link-configs.sh
git diff --check
```

Expected: all checks pass.

- [x] **Step 5: Apply the settings to the current desktop**

Run the two `gsettings set` commands and remove the existing `.xprofile` symlink only if it points to this repository's deleted `.xprofile`.
