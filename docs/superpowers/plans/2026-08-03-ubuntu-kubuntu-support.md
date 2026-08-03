# Ubuntu and Kubuntu Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make bootstrap support Ubuntu 24.04 Cinnamon and Kubuntu 26.04 KDE explicitly, while carrying the selected Yomitan archives in the repository.

**Architecture:** Keep one bootstrap and dispatch by the `VERSION_ID` from an overridable os-release file plus `XDG_CURRENT_DESKTOP`. Share packages and setup logic between both targets; branch only desktop-specific behavior and manual documentation.

**Tech Stack:** Bash, Markdown, existing Bash test harness, ordinary Git-tracked ZIP archives

## Global Constraints

- Support exactly Ubuntu 24.04 with Cinnamon and Ubuntu 26.04 with KDE Plasma from a Kubuntu ISO.
- Reject other release/desktop combinations before package installation or configuration.
- Do not install or convert desktop environments.
- Keep `configs/system/keyboard` as the keyboard source of truth.
- Use ordinary Git, not Git LFS, for the eight existing dictionary archives.
- Do not commit or stage the existing dirty worktree.

---

### Task 1: Platform and package compatibility

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `scripts/setup.sh`
- Modify: `scripts/bootstrap/install-packages.sh`

**Interfaces:**
- Consumes: `OS_RELEASE_FILE` containing shell-compatible `ID` and `VERSION_ID`, plus `XDG_CURRENT_DESKTOP`.
- Produces: successful setup only for `24.04:*Cinnamon*` and `26.04:*KDE*`.

- [ ] **Step 1: Write failing checks**

Add Ubuntu 24.04 and Kubuntu 26.04 os-release fixtures. Run setup with fake privileged/external commands for both supported desktop pairs, and run an unsupported pair with an empty mutation log. Assert the package file contains `libncurses-dev` and excludes `libncursesw5-dev`.

- [ ] **Step 2: Verify failure**

Run `bash tests/bootstrap.sh`. Expect failure because setup ignores `OS_RELEASE_FILE`, accepts every Ubuntu version/desktop, and still contains `libncursesw5-dev`.

- [ ] **Step 3: Implement the minimal validation**

In `scripts/setup.sh`, read `${OS_RELEASE_FILE:-/etc/os-release}` and validate before defining or invoking bootstrap helpers:

```bash
case "${VERSION_ID:-}:${XDG_CURRENT_DESKTOP:-}" in
24.04:*Cinnamon* | 26.04:*KDE*) ;;
*)
    printf 'Unsupported platform: Ubuntu %s with %s.\n' \
        "${VERSION_ID:-unknown}" "${XDG_CURRENT_DESKTOP:-unknown}" >&2
    exit 1
    ;;
esac
```

Replace `libncursesw5-dev` with `libncurses-dev` in the shared package list.

- [ ] **Step 4: Verify task**

Run `bash tests/bootstrap.sh`. Expect the supported fixtures to pass, the unsupported fixture to leave its mutation log empty, and all prior checks to pass.

---

### Task 2: sudo-rs compatibility

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `scripts/optional/system/disable-sudo-admin-flag.sh`

**Interfaces:**
- Consumes: first line of `sudo --version`.
- Produces: no-op exit 0 for sudo-rs; legacy `admin_flag` and Bash hint cleanup for classic sudo.

- [ ] **Step 1: Write failing checks**

Add fake `sudo` implementations for sudo-rs and classic sudo. Assert the sudo-rs run records no privileged mutation, while the classic run records the sudoers-file write.

- [ ] **Step 2: Verify failure**

Run `bash tests/bootstrap.sh`. Expect the sudo-rs case to fail because the current script always writes `Defaults !admin_flag`.

- [ ] **Step 3: Add the provider guard**

Make the script strict and exit before all mutations when `sudo --version` identifies sudo-rs:

```bash
if sudo --version 2>/dev/null | head -n 1 | grep -qi 'sudo-rs'; then
    echo 'sudo-rs does not create ~/.sudo_as_admin_successful; nothing to configure.'
    exit 0
fi
```

Keep the existing classic-sudo operations unchanged.

- [ ] **Step 4: Verify task**

Run `bash tests/bootstrap.sh`. Expect both provider cases and all prior checks to pass.

---

### Task 3: Dictionary and runbook coverage

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `README.md`
- Verify: `japanese/yomitan/dictionaries.txt`
- Verify: `japanese/yomitan/dictionaries/`

**Interfaces:**
- Consumes: tab-separated dictionary manifest entries and their filenames.
- Produces: eight present, non-ignored archives below 100,000,000 bytes and a two-target runbook.

- [ ] **Step 1: Write failing documentation/data checks**

Parse non-comment manifest entries, assert there are exactly eight, each named archive exists, each is below 100,000,000 bytes, and `git check-ignore` does not match it. Require README headings for Ubuntu 24.04 Cinnamon and Kubuntu 26.04 KDE.

- [ ] **Step 2: Verify failure**

Run `bash tests/bootstrap.sh`. Expect failure because the README still documents only Ubuntu 24.04 and gives Cinnamon-only desktop steps as universal.

- [ ] **Step 3: Update the runbook**

Document the exact supported pairs. Keep shared steps once, place GNOME Terminal and LightDM under Ubuntu 24.04 Cinnamon, state that Kubuntu uses its installed KDE terminal/display manager, and explain that the eight dictionary ZIPs are carried directly while the downloader restores or refreshes them.

- [ ] **Step 4: Run final verification**

Run:

```bash
bash tests/bootstrap.sh
git diff --check -- README.md scripts/setup.sh scripts/bootstrap/install-packages.sh \
    scripts/optional/system/disable-sudo-admin-flag.sh tests/bootstrap.sh
```

Expect `All checks passed!`, exit status 0, no whitespace errors, all eight archives present, and no Git ignore matches.
