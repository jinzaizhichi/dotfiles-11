# Layout-Aware Grave Key Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reverse tilde and backtick only in the US layout while preserving standard Russian `ё`/`Ё` behavior.

**Architecture:** A standalone XKB layout owns language-sensitive symbol levels. Kanata passes the grave key through and remains responsible only for layout-independent ergonomic behavior.

**Tech Stack:** XKB symbols, Kanata, Bash bootstrap tests

## Global Constraints

- Support Ubuntu 24.04 Cinnamon/X11 and Kubuntu 26.04 Plasma/Wayland.
- Do not edit packaged XKB files.
- Preserve Kanata sticky Shift and the Space symbol layer.
- Leave Windows and macOS layout definitions out of scope.

---

### Task 1: Move grave-key levels from Kanata to XKB

**Files:**
- Create: `configs/system/xkb/symbols/tilde-first`
- Modify: `configs/system/keyboard`
- Modify: `configs/xdg/kanata/kanata.kbd`
- Modify: `scripts/bootstrap/configure-desktop.sh`
- Modify: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: `configs/system/keyboard` as the shared desktop layout source.
- Produces: the `tilde-first,ru` XKB layout pair and an unchanged Kanata `grv` output.

- [ ] **Step 1: Add failing bootstrap assertions**

Require `XKBLAYOUT="tilde-first,ru"`, verify that the bootstrap installs the custom symbols file at `/usr/share/X11/xkb/symbols/tilde-first`, update Cinnamon and KDE expectations, and require the default Kanata layer to contain `grv` rather than `@grave`.

- [ ] **Step 2: Verify the assertions fail**

Run: `bash tests/bootstrap.sh`

Expected: failure because the custom layout does not exist and the old layout names remain configured.

- [ ] **Step 3: Add the minimal XKB layout**

Create `configs/system/xkb/symbols/tilde-first`:

```xkb
default partial alphanumeric_keys
xkb_symbols "basic" {
    include "us(basic)"
    name[Group1] = "English (US, tilde first)";
    key <TLDE> { [ asciitilde, grave ] };
};
```

Set `XKBLAYOUT="tilde-first,ru"`, install the symbols file before `/etc/default/keyboard`, and replace Kanata's `@grave` mapping with `grv` while deleting the `grave` alias.

- [ ] **Step 4: Verify syntax and regression tests**

Run:

```bash
setxkbmap -I"$PWD/configs/system/xkb" -layout tilde-first,ru -variant , \
    -option grp:alt_shift_toggle -print |
    xkbcomp -I"$PWD/configs/system/xkb" -xkb - /dev/null
kanata --check --cfg configs/xdg/kanata/kanata.kbd
bash tests/bootstrap.sh
```

Expected: XKB and Kanata configurations validate and the suite prints `All checks passed!`.

- [ ] **Step 5: Apply the live configuration**

Run the desktop configuration script, restart the Kanata user service, and verify:

```text
US:      ~ → ~, Shift+~ → `
Russian: ~ → ё, Shift+~ → Ё
```
