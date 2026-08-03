# Python Project Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make uv and ty share each project's visible `venv` directory without `workon`.

**Architecture:** `.profile` selects uv's relative project environment path. A
user-level ty configuration selects the same relative path and is linked by the
existing XDG bootstrap loop.

**Tech Stack:** POSIX shell, uv, ty, TOML

## Global Constraints

- Use `<project>/venv`.
- Do not generate project-local editor configuration.
- Do not add dependencies.

---

### Task 1: Configure uv and ty globally

**Files:**
- Create: `configs/xdg/ty/ty.toml`
- Modify: `.profile`
- Modify: `tests/python-environment.sh`

**Interfaces:**
- Consumes: `$XDG_CONFIG_HOME` and each Python project root.
- Produces: `UV_PROJECT_ENVIRONMENT=venv` and ty environment discovery at `venv`.

- [ ] Add an integration test that sources `.profile` and runs ty against a dependency available only in `<project>/venv`.
- [ ] Run `bash tests/python-environment.sh`; expect failure because the global settings do not exist.
- [ ] Export `UV_PROJECT_ENVIRONMENT=venv` and add the user-level ty configuration.
- [ ] Run `bash tests/python-environment.sh`; expect success.

### Task 2: Remove workon

**Files:**
- Delete: `bin/workon`
- Delete: `tests/workon.sh`
- Modify: `tests/bootstrap.sh`

**Interfaces:**
- Consumes: the global uv and ty configuration from Task 1.
- Produces: a bootstrap without the obsolete `workon` command.

- [ ] Update the bootstrap integration test to expect the ty configuration and no `workon` command.
- [ ] Delete `workon` and its dedicated test.
- [ ] Run `bash tests/python-environment.sh` and `bash tests/bootstrap.sh`; expect success.
- [ ] Run shell syntax and whitespace checks.
