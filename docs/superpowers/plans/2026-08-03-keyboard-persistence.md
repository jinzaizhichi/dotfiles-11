# Keyboard Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the `us,ru` XKB map across reboots and apply it immediately to the current X11 session.

**Architecture:** Extend the existing desktop configuration entry point. A repo-owned `/etc/default/keyboard` is installed as Ubuntu's system XKB default; the existing Cinnamon/KDE settings remain responsible for desktop integration, while `setxkbmap` updates an available live X11 session.

**Tech Stack:** Bash, Ubuntu `/etc/default/keyboard`, XKB `setxkbmap`, existing shell test harness

## Global Constraints

- Configure US and Russian layouts with `grp:alt_shift_toggle`.
- Keep repeat delay at 220 ms and repeat rate at 40 per second.
- Do not restore `.xprofile` or add a login autostart script.

---

### Task 1: Persist and apply the keyboard map

**Files:**
- Create: `configs/system/keyboard`
- Modify: `tests/bootstrap.sh`
- Modify: `scripts/bootstrap/configure-desktop.sh`

**Interfaces:**
- Consumes: `XDG_CURRENT_DESKTOP`, optional `DISPLAY`, `sudo`, `install`, and `setxkbmap` commands.
- Produces: system XKB defaults plus the existing Cinnamon/KDE desktop settings.

- [ ] **Step 1: Write the failing test**

Add a fake `setxkbmap` command that logs arguments. Assert that setup invokes:

```text
install -m 644 REPO/configs/system/keyboard /etc/default/keyboard
-layout us,ru -option  -option grp:alt_shift_toggle
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap.sh`

Expected: FAIL because neither command is currently invoked.

- [ ] **Step 3: Write minimal implementation**

Create `configs/system/keyboard` with `pc105`, layouts `us,ru`, variants `,`, and option `grp:alt_shift_toggle`. At the start of `configure-desktop.sh`, run:

```bash
sudo install -m 644 "$repo/configs/system/keyboard" /etc/default/keyboard
```

After desktop-specific configuration, apply the same map only when `DISPLAY` is non-empty and `setxkbmap` exists:

```bash
if [ -n "${DISPLAY:-}" ] && command -v setxkbmap >/dev/null; then
	setxkbmap -layout us,ru -option '' -option grp:alt_shift_toggle
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap.sh`

Expected: PASS.

- [ ] **Step 5: Verify the live machine**

Run the configuration script with the current display, then inspect `/etc/default/keyboard` and `setxkbmap -query`. Expected layouts: `us,ru`; expected option: `grp:alt_shift_toggle`.
