# Bob-managed Neovim Nightly Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install Bob with Mise and have Bob install and select Neovim nightly during bootstrap.

**Architecture:** Extend the existing Mise tool declaration and installation command. Invoke Bob through `mise exec` so bootstrap does not depend on an activated shell or populated shim path.

**Tech Stack:** Bash, Mise TOML, Bob

## Global Constraints

- Ubuntu's `neovim` package remains absent.
- Existing Neovim/AppImage files are not deleted automatically.
- Network operations are represented by the existing test doubles.

---

### Task 1: Install Bob and select Neovim nightly

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `configs/xdg/mise/config.toml`
- Modify: `scripts/bootstrap/install-mise.sh`
- Modify: `.profile`

**Interfaces:**
- Consumes: the existing `mise install --yes ...` bootstrap command.
- Produces: a Bob-managed `nvim` selected by `bob use nightly`.

- [ ] **Step 1: Write the failing test**

Add `bob` to the expected Mise install command and declared-tool loop, then require this emitted command:

```sh
grep -Fqx 'exec -- bob use nightly' "$temp_dir/mise.log"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap.sh`

Expected: FAIL because Bob is not installed or invoked.

- [ ] **Step 3: Write minimal implementation**

Declare `bob = "latest"`, include `bob` in the existing install command, add
`$XDG_DATA_HOME/bob/nvim-bin` to the login PATH, and append:

```sh
"$mise_bin" exec -- bob use nightly
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap.sh`

Expected: exit 0.

- [ ] **Step 5: Verify shell syntax and diff hygiene**

Run: `bash -n scripts/bootstrap/install-mise.sh && git diff --check`

Expected: exit 0.
