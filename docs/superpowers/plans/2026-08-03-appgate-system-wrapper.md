# Appgate System Wrapper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route every Appgate launch through its fake XDG home without stopping the currently running VPN.

**Architecture:** Keep one reusable wrapper in `bin/appgate`. An explicit optional system script uses Debian's native `dpkg-divert` mechanism to preserve the vendor executable as `/usr/bin/appgate.vendor` and installs the wrapper at `/usr/bin/appgate`.

**Tech Stack:** POSIX shell, `dpkg-divert`, `install`, existing shell test harness

## Global Constraints

- Do not stop, restart, disconnect, or signal Appgate.
- Do not alter the Appgate system driver.
- Do not use a home-directory symlink for `.appgate`.
- Remove `~/.appgate` only after confirming no Appgate process has files open there.

---

### Task 1: Make the wrapper compatible with package diversion

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `bin/appgate`

**Interfaces:**
- Consumes: optional `APPGATE_BIN`, otherwise `/usr/bin/appgate.vendor`.
- Produces: a process whose `HOME` is `$XDG_DATA_HOME/appgate/home`, forwarding all arguments unchanged.

- [ ] **Step 1: Write the failing test**

Assert that the wrapper's default executable is `/usr/bin/appgate.vendor`. The existing harmless `APPGATE_BIN` test continues to cover execution, fake-home creation, and argument forwarding.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap.sh`

Expected: FAIL because the wrapper currently defaults back to `/usr/bin/appgate`.

- [ ] **Step 3: Write minimal implementation**

Select `APPGATE_BIN`, otherwise `/usr/bin/appgate.vendor`:

```sh
exec "${APPGATE_BIN:-/usr/bin/appgate.vendor}" "$@"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap.sh`

Expected: PASS.

### Task 2: Install the system interception idempotently

**Files:**
- Create: `scripts/optional/system/configure-appgate-xdg.sh`
- Modify: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: repository `bin/appgate`, package-owned `/usr/bin/appgate`, `sudo`, `dpkg-divert`, and `install`.
- Produces: `/usr/bin/appgate.vendor` plus the wrapper at `/usr/bin/appgate`.

- [ ] **Step 1: Write the failing test**

Use fake `sudo`, `dpkg-divert`, and `install` commands. Assert the optional script requests exactly one diversion and installs the repository wrapper at `/usr/bin/appgate`; also add it to `expected_scripts`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap.sh`

Expected: FAIL because the optional script does not exist.

- [ ] **Step 3: Write minimal implementation**

Create an executable script which validates `/usr/bin/appgate`, skips an already registered matching diversion, otherwise runs:

```bash
sudo dpkg-divert --add --rename \
	--divert /usr/bin/appgate.vendor /usr/bin/appgate
sudo install -m 755 "$repo/bin/appgate" /usr/bin/appgate
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap.sh`

Expected: PASS.

- [ ] **Step 5: Install without touching the running process**

Record the running Appgate PIDs, run the optional configuration script, and confirm the same PIDs remain. Recheck open files under `~/.appgate`; only if none exist, remove that exact directory.
