# Appgate Fake Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run Appgate with an isolated XDG-backed home.

**Architecture:** A small command wrapper shadows `/usr/bin/appgate` through the existing `~/.local/bin` setup. Existing Appgate state moves into that fake home.

**Tech Stack:** POSIX shell, existing bootstrap shell tests

## Global Constraints

- Do not create `~/.appgate` or a compatibility symlink.
- Preserve all existing Appgate state.
- Do not modify Appgate's package files or system services.

---

### Task 1: Add and install the Appgate wrapper

**Files:**
- Create: `bin/appgate`
- Modify: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: `XDG_DATA_HOME`, command-line arguments
- Produces: Appgate process with `HOME=$XDG_DATA_HOME/appgate/home`

- [x] **Step 1: Write the failing wrapper behavior test**

```bash
appgate_test="$temp_dir/appgate"
mkdir -p "$appgate_test/bin" "$appgate_test/data"
cat >"$appgate_test/bin/real-appgate" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$HOME" "$*"
EOF
chmod +x "$appgate_test/bin/real-appgate"
output="$(XDG_DATA_HOME="$appgate_test/data" \
    APPGATE_BIN="$appgate_test/bin/real-appgate" \
    "$repo/bin/appgate" --url=appgate://example)"
test "$output" = "$appgate_test/data/appgate/home
--url=appgate://example"
test -d "$appgate_test/data/appgate/home"
```

- [x] **Step 2: Run `./tests/bootstrap.sh` and confirm it fails because `bin/appgate` is absent**
- [x] **Step 3: Add the minimal wrapper**

```sh
#!/bin/sh
set -eu

real_home="$HOME"
export HOME="${XDG_DATA_HOME:-$real_home/.local/share}/appgate/home"
mkdir -p "$HOME"
exec "${APPGATE_BIN:-/usr/bin/appgate}" "$@"
```

- [x] **Step 4: Run `./tests/bootstrap.sh` and confirm it passes**
- [x] **Step 5: Link the wrapper into `~/.local/bin`**

```bash
ln -s "$PWD/bin/appgate" "$HOME/.local/bin/appgate"
```

### Task 2: Migrate and verify live state

**Files:**
- Move: `~/.appgate` to `~/.local/share/appgate/home/.appgate`
- Modify: `~/.local/share/appgate/home/.appgate/log/.ui.audit.log`

**Interfaces:**
- Consumes: Existing Appgate state
- Produces: Preserved state under the fake home

- [x] **Step 1: Confirm Appgate is not running**
- [x] **Step 2: Move the existing directory without deleting its contents**

```bash
mkdir -p "$XDG_DATA_HOME/appgate/home"
mv "$HOME/.appgate" "$XDG_DATA_HOME/appgate/home/.appgate"
sed -i "s#$HOME/.appgate/log#$XDG_DATA_HOME/appgate/home/.appgate/log#g" \
    "$XDG_DATA_HOME/appgate/home/.appgate/log/.ui.audit.log"
```

- [x] **Step 3: Run the wrapper with `--version`**
- [x] **Step 4: Confirm `~/.appgate` remains absent**
