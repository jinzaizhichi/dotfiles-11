# Kokoro Connect TV Subtitle Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install source-faithful Japanese and English trial subtitles beside the 13 Timecraft/NASTR Kokoro Connect TV episodes without changing the MKVs.

**Architecture:** Stage the two supplied archives under `/tmp`, use the existing conservative subtitle helper to filter only approved non-dialogue cues, generate a complete preview, verify it against the sources, then copy it into local `subs.jp/` and `subs.en/` directories. No permanent processing code, dotfiles subtitle set, mpv profile, or filename change is needed for this trial.

**Tech Stack:** Python 3 standard library, `unzip`, `unrar`, `ffprobe`, `sha256sum`.

## Global Constraints

- Never modify, remux, or rename the 13 MKV files.
- Apply no timing shift or cross-language alignment.
- Never merge, split, stretch, translate, deduplicate, or reorder dialogue cues.
- Japanese removals are limited to song-marked cues and pure sound descriptions.
- English removals are limited to events whose style is not `CRKokoro`.
- Keep ambiguous simultaneous or background dialogue.
- Install locally only; do not add a Kokoro dotfiles folder or mpv profile yet.

---

### Task 1: Freeze inputs and verify source counts

**Files:**
- Read: `/tmp/Kokoro Connect (01-17).zip`
- Read: `/tmp/[HorribleSubs]_Kokoro_Connect_01-13.rar`
- Read: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/*.mkv`
- Create: `/tmp/kokoro-tv-reset/mkv-before.sha256`
- Create: `/tmp/kokoro-tv-reset/jp/`
- Create: `/tmp/kokoro-tv-reset/en/`

**Interfaces:**
- Consumes: the downloaded archives and completed 13-episode release.
- Produces: 13 Japanese SRTs, 13 English ASS files, and immutable pre-install video hashes.

- [ ] **Step 1: Hash the videos**

Run `sha256sum` over the 13 sorted MKVs and save the results to `/tmp/kokoro-tv-reset/mkv-before.sha256`.

- [ ] **Step 2: Extract source episodes**

Extract Japanese episodes 1–13 only and all 13 HorribleSubs ASS files into the existing `/tmp/kokoro-tv-reset/jp` and `/tmp/kokoro-tv-reset/en` directories.

- [ ] **Step 3: Verify counts**

Require exactly 13 MKVs, 13 Japanese SRTs, and 13 English ASS files before continuing.

---

### Task 2: Build and self-check the one-off transformer

**Files:**
- Reuse: `/tmp/conservative_subtitle_reset.py`
- Create: `/tmp/kokoro_tv_trial.py`
- Create: `/tmp/test_kokoro_tv_trial.py`

**Interfaces:**
- Consumes: `parse_srt`, `filter_ass`, `render_srt`, `is_song`, `is_non_dialogue_description`, and `is_empty` from the existing helper.
- Produces: `filter_japanese(cues) -> (kept, removed)` and complete files under `/tmp/kokoro-tv-reset/preview/`.

- [ ] **Step 1: Write the self-check**

Assert that Japanese dialogue survives unchanged, `♪` lyrics and `（ドアの音）` are removed, English `CRKokoro` survives unchanged, and English `Sign` events are removed.

- [ ] **Step 2: Verify the self-check fails**

Run `PYTHONPATH=/tmp python3 /tmp/test_kokoro_tv_trial.py` and require failure because the trial transformer does not exist yet.

- [ ] **Step 3: Implement the minimum transformer**

Use the existing helper. Render Japanese with `offset=0`; filter English with the exact allowlist `{'CRKokoro'}` and `offset=0`. Name outputs from the unchanged MKV stems:

```text
subs.jp/<video-stem>.ja.srt
subs.en/<video-stem>.en.ass
```

- [ ] **Step 4: Verify the self-check passes**

Run `PYTHONPATH=/tmp python3 /tmp/test_kokoro_tv_trial.py` and require all assertions to pass.

---

### Task 3: Generate and validate the preview

**Files:**
- Create: `/tmp/kokoro-tv-reset/preview/subs.jp/`
- Create: `/tmp/kokoro-tv-reset/preview/subs.en/`
- Create: `/tmp/kokoro-tv-reset/report.csv`

**Interfaces:**
- Consumes: the 26 staged source subtitles.
- Produces: 26 verified trial subtitle files and removal counts by episode/language/category.

- [ ] **Step 1: Generate all outputs**

Run `PYTHONPATH=/tmp python3 /tmp/kokoro_tv_trial.py` and require 13 Japanese plus 13 English files.

- [ ] **Step 2: Verify source fidelity**

Independently parse every source/output pair and assert that each surviving cue has identical text, start, end, and order after subtracting only approved removals.

- [ ] **Step 3: Verify timing validity**

Require every surviving cue to satisfy `0 <= start <= end <= video_duration + 1000 ms`.

- [ ] **Step 4: Parse every output**

Run `ffprobe -v error` against all 26 preview files and require no failures.

---

### Task 4: Install and verify the local trial

**Files:**
- Create: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/subs.jp/`
- Create: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/subs.en/`

**Interfaces:**
- Consumes: the verified preview.
- Produces: locally testable Japanese-primary and English-secondary external subtitles.

- [ ] **Step 1: Install only the preview files**

Create the two subtitle directories and copy the preview contents into them. Do not touch any other local file.

- [ ] **Step 2: Verify installed copies**

Require all 26 installed files to be byte-identical to the preview.

- [ ] **Step 3: Verify MKVs remain unchanged**

Run `sha256sum --check /tmp/kokoro-tv-reset/mkv-before.sha256` and require all 13 videos to report `OK`.

- [ ] **Step 4: Provide the test command**

Use explicit subtitle files because the dotfiles/mpv profile is intentionally deferred:

```sh
mpv 'Kokoro_Connect_TV_[01]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].mkv' \
  --aid=2 \
  --sub-file='subs.jp/Kokoro_Connect_TV_[01]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].ja.srt' \
  --sub-file='subs.en/Kokoro_Connect_TV_[01]_[ru_jp]_[Timecraft_&_NASTR_&_Animereactor].en.ass' \
  --slang=ja,en --sid=auto --secondary-sid=auto
```
