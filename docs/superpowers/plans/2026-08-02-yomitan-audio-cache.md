# Yomitan Local Audio Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make local Yomitan audio restoration explicit, cache-backed, and non-blocking for the main bootstrap.

**Architecture:** The study setup only detects installed add-on data and prints recovery guidance. A separate optional Bash script owns the torrent download, archive validation, and extraction.

**Tech Stack:** Bash, aria2c, tar, the existing bootstrap integration test.

## Global Constraints

- Do not automatically start the 2.5 GiB download.
- Do not fail the main setup when local audio is absent.
- Cache downloads under `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/yomitan-audio`.
- Preserve installed audio and unrelated Anki add-on files.

---

### Task 1: Test the observable setup and downloader behavior

**Files:**
- Modify: `tests/bootstrap.sh`

- [ ] Run the study setup without the audio archive or installed `user_files` and assert that it succeeds and names `download-yomitan-audio.sh`.
- [ ] Run the downloader against a controlled aria2c boundary and a real miniature tar.xz archive; assert extraction into add-on 1045800357.
- [ ] Run the downloader again with installed data and assert that aria2c is not called.
- [ ] Run `bash tests/bootstrap.sh` and confirm failure before implementation.

### Task 2: Implement the minimum split

**Files:**
- Create: `scripts/optional/download-yomitan-audio.sh`
- Modify: `scripts/optional/setup-japanese-study.sh`
- Modify: `README.md`

- [ ] Replace the `~/Downloads` archive assertion with a non-failing installed-data check.
- [ ] Download Nyaa torrent 1681655 from its documented magnet using aria2c, cache its archive, validate `user_files/`, and extract into the add-on directory.
- [ ] Document the explicit downloader in the optional scripts table.
- [ ] Run `bash tests/bootstrap.sh`, ShellCheck, Bash syntax checks, and `git diff --check`.
