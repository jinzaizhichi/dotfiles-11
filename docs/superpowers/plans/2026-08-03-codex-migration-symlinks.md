# Codex Migration Symlink Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep `codex` executable immediately after moving Codex state from `~/.codex` to `$XDG_DATA_HOME/codex`.

**Architecture:** Extend the existing one-shot migration to preserve the selected standalone release while rewriting its absolute `current` link and the stable `~/.local/bin/codex` link. Exercise the real migration script against a temporary home.

**Tech Stack:** Bash, symbolic links, existing shell bootstrap checks

## Global Constraints

- Preserve the release selected before migration.
- Refuse to overwrite an existing target Codex home.
- Do not add a wrapper or a versioned directory to `PATH`.

---

### Task 1: Repair launcher symlinks during migration

**Files:**
- Modify: `tests/bootstrap.sh`
- Modify: `scripts/optional/shell/migrate-codex-home.sh`

**Interfaces:**
- Consumes: an old `$HOME/.codex`, its standalone `current` symlink, and `$XDG_DATA_HOME`.
- Produces: a moved Codex home whose `current` and `$HOME/.local/bin/codex` links resolve under the new location.

- [x] **Step 1: Add the failing regression check**

Create a temporary old Codex home with release `0.146.0`, an absolute
`packages/standalone/current` link into `~/.codex`, and an absolute
`~/.local/bin/codex` link. Use a fake `pgrep` that reports no Codex process,
run `migrate-codex-home.sh`, and assert both links resolve into the new home.

- [x] **Step 2: Verify the regression check fails**

Run `./tests/bootstrap.sh`. Expect failure because the moved links still point
to the removed old home.

- [x] **Step 3: Implement minimal link repair**

Before moving, record the basename selected by `current`. After moving, replace
`current` with a relative `releases/<version>` link and replace
`~/.local/bin/codex` with a link to the new `current/bin/codex`.

- [x] **Step 4: Verify all checks**

Run:

```sh
./tests/bootstrap.sh
sh -n scripts/optional/shell/migrate-codex-home.sh
shfmt -d scripts/optional/shell/migrate-codex-home.sh
git diff --check
```

Expected: every command exits successfully.
