# Modern CLI Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install `bat`, `eza`, `delta`, and `bottom` reproducibly and make Delta Git's pager without replacing standard Unix commands.

**Architecture:** Mise owns all four executables through the existing declarative tool configuration and bootstrap installer. The tracked Git configuration enables Delta; no shell aliases are added.

**Tech Stack:** Mise, Git configuration, Bash regression tests

## Global Constraints

- Keep `bat`, `eza`, and `btm` explicit commands.
- Do not alias `cat`, `ls`, or `top`.
- Preserve the existing Neovim diff and merge tools.

---

### Task 1: Install and configure the modern CLI tools

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `configs/xdg/mise/config.toml`
- Modify: `scripts/bootstrap/install-mise.sh`
- Modify: `configs/xdg/git/config`

**Interfaces:**
- Consumes: Mise's `[tools]` configuration and `scripts/bootstrap/install-mise.sh` invocation.
- Produces: `bat`, `eza`, `delta`, and `btm` on `PATH`; Git pager values readable through `git config`.

- [ ] **Step 1: Write the failing bootstrap assertions**

Extend the expected Mise invocation with `bat eza delta bottom`, add those names to the declarative-tool loop, and assert:

```bash
test "$(git config --file "$repo/configs/xdg/git/config" --get core.pager)" = delta
test "$(git config --file "$repo/configs/xdg/git/config" --get interactive.diffFilter)" = \
    'delta --color-only'
```

- [ ] **Step 2: Verify the assertions fail**

Run: `bash tests/bootstrap.sh`

Expected: failure because the Mise invocation and Git configuration do not contain the new tools.

- [ ] **Step 3: Add the minimal implementation**

Add these entries to `configs/xdg/mise/config.toml`:

```toml
bat = "latest"
eza = "latest"
delta = "latest"
bottom = "latest"
```

Pass the same four names to `mise install --yes` in `scripts/bootstrap/install-mise.sh`. Add to `configs/xdg/git/config`:

```gitconfig
[core]
  pager = delta
[interactive]
  diffFilter = delta --color-only
[delta]
  navigate = true
```

Keep the existing `[core]`, `[interactive]`, and `[delta]` sections consolidated rather than duplicated.

- [ ] **Step 4: Verify the repository**

Run: `bash tests/bootstrap.sh`

Expected: `All checks passed!`

- [ ] **Step 5: Install and smoke-test the tools locally**

Run:

```bash
mise install bat eza delta bottom
bat --version
eza --version
delta --version
btm --version
```

Expected: every command exits successfully and prints a version.
