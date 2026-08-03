# Local New Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route Firefox and Vimium new-tab commands through a private loopback page where Vimium can run.

**Architecture:** Track HTML and WebP assets under `configs/xdg/new-tab` and serve them only on `127.0.0.1:8766` from a systemd user service. Vimium creates the browser's default new tab; New Tab Override redirects it to the normal HTTP origin.

**Tech Stack:** HTML, CSS, WebP, Python standard-library HTTP server, systemd user service, Bash assertion tests

## Global Constraints

- Preserve the existing full-height, zero-margin, no-repeat, cover-sized, right-centered background.
- Do not patch extensions, expose the server beyond loopback, or mutate Firefox extension storage.
- Preserve all unrelated staged and working-tree changes.

---

### Task 1: Loopback new-tab page

**Files:**
- Create: `configs/xdg/new-tab/blank.html`
- Create: `configs/xdg/new-tab/background.webp`
- Create: `configs/xdg/new-tab/new-tab.service`
- Create: `scripts/optional/firefox/configure-new-tab.sh`
- Modify: `tests/bootstrap.sh`
- Modify: `README.md`

- [x] Add failing assertions for the XDG link, assets, unit, script, and layout.
- [x] Verify the test fails before the new page exists.
- [x] Create the page, separate WebP, loopback unit, and enabling script.
- [x] Document the New Tab Override and Vimium settings.
- [ ] Run the complete bootstrap, lint, file-format, and rendering checks.
- [ ] Import the page and confirm `Ctrl+T` plus Vimium `t` open it.
