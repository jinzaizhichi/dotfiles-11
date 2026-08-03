# Mise CLI Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move versioned command-line tools from Zinit to Mise.

**Architecture:** Keep shell plugins in Zinit and declare versioned binaries in `configs/xdg/mise/config.toml`. Bootstrap Mise with its official installer, then install the declared toolset.

**Tech Stack:** Bash, Zsh, Mise, TOML

## Global Constraints

- Preserve existing Mise-managed language versions.
- Do not let bootstrap tests access the network.
- Mason owns StyLua; `yq` is not installed.

---

### Task 1: Declare and bootstrap tools

**Files:**
- Create: `configs/xdg/mise/config.toml`
- Create: `scripts/bootstrap/install-mise.sh`
- Modify: `scripts/setup.sh`
- Modify: `configs/xdg/zsh/.zshrc`
- Test: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: the existing XDG link loop and official `https://mise.run` installer.
- Produces: all six commands through Mise shims inherited from `.profile`.

- [ ] Add assertions for the tracked Mise configuration, installer invocation, and absent Zinit command declarations.
- [ ] Run `bash tests/bootstrap.sh` and confirm those assertions fail.
- [ ] Add the minimal Mise config and installer, call it from setup, and delete the Zinit command blocks.
- [ ] Run `bash tests/bootstrap.sh`, `zsh -n configs/xdg/zsh/.zshrc`, and `git diff --check`.
