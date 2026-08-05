# Conservative Anime Subtitle Reset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild five anime subtitle sets from their original sources with timing-only synchronization and conservative non-dialogue filtering, while removing the obsolete DB Kokoro Connect release.

**Architecture:** Work from untouched archives and freshly extracted embedded English tracks in `/tmp`. A one-off standard-library Python script will preserve cue text, order, boundaries, and styles while applying measured timestamp transforms and an explicit dialogue-style allowlist; it will not perform bilingual alignment or semantic rewriting. Preview and verify every output before replacing local and dotfiles copies.

**Tech Stack:** Python 3 standard library, `ffmpeg`/`ffprobe`, `unzip`, `unrar`, `7z`, `gio trash`, Git.

## Global Constraints

- Never modify or remux retained MKV files.
- Leave `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect` untouched.
- Never merge, split, stretch, duplicate, translate, or semantically rewrite dialogue cues.
- Never alter timing merely to force Japanese/English overlap.
- Remove only songs, signs, credits, typesetting, animation numbers, and source-metadata-confirmed background chatter.
- Keep ambiguous overlapping dialogue.
- Preserve original styles except the approved Erased Japanese font-size-outline override.
- Do not install or run speech-recognition or language models.

---

### Task 1: Remove the obsolete Kokoro Connect release and processing artifacts

**Files:**
- Trash: `/home/evakuator/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)`
- Delete: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/`
- Delete: `/home/evakuator/dotfiles/japanese/anime/subtitles/handoff/`
- Delete: `/home/evakuator/dotfiles/docs/superpowers/specs/2026-08-05-subtitle-semantic-audit-design.md`
- Delete: `/home/evakuator/dotfiles/docs/superpowers/plans/2026-08-05-subtitle-semantic-audit-plan.md`
- Modify: `/home/evakuator/dotfiles/configs/xdg/mpv/mpv.conf`
- Modify: `/home/evakuator/dotfiles/japanese/anime/torrent-links.txt`

**Interfaces:**
- Consumes: the approved deletion scope from the design.
- Produces: no active or documented dependency on the obsolete DB release.

- [ ] **Step 1: Resolve the exact deletion targets**

Run:

```sh
test -d '/home/evakuator/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)'
test -d '/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect'
```

Expected: both tests pass before deletion.

- [ ] **Step 2: Send only the DB directory to Trash**

Run:

```sh
gio trash '/home/evakuator/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)'
```

Expected: the DB directory disappears from `Shared`; the Timecraft directory remains.

- [ ] **Step 3: Remove tracked Kokoro and obsolete audit artifacts**

Use `git rm -r` for the dotfiles Kokoro and handoff directories and `git rm` for the two obsolete semantic-audit documents. Remove the `[kokoro-connect]` block from `configs/xdg/mpv/mpv.conf` and the old DB torrent line from `japanese/anime/torrent-links.txt`.

- [ ] **Step 4: Verify scope**

Run:

```sh
test ! -e '/home/evakuator/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)'
test -d '/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect'
rg -n -i 'kokoro' /home/evakuator/dotfiles/configs/xdg/mpv/mpv.conf /home/evakuator/dotfiles/japanese/anime/subtitles /home/evakuator/dotfiles/japanese/anime/torrent-links.txt
```

Expected: the first two tests pass and `rg` finds only the new design/plan references, not active configuration or old reports.

---

### Task 2: Stage pristine sources and target-matched English tracks

**Files:**
- Read: `/home/evakuator/Videos/Monogatari Series/01. Bakemonogatari/Bakemonogatari (01-15) (Webrip).zip`
- Read: `/home/evakuator/Shared/[Judas] Boku Dake ga Inai Machi (Erased) (Season 1) [BD 1080p][HEVC x265 10bit][Dual-Audio][Eng-Subs]/[Kamigami] Boku dake ga Inai Machi (Synced for HorribleSubs).rar`
- Read: `/home/evakuator/Shared/Sonny Boy [BD][1080p][HEVC 10bit x265][Dual Audio][Tenrai-Sensei]/SonnyBoy.zip`
- Read: `/home/evakuator/Shared/Wonder Egg Priority [BD][1080p][HEVC 10bit x265][Dual Audio][Tenrai-Sensei]/WonderEggPriority-JPSC.zip`
- Download: `/tmp/subtitle-reset/Freshly ripped from netflix timed to philosophy raws.7z`
- Create: `/tmp/subtitle-reset/originals/`
- Create: `/tmp/subtitle-reset/english/`
- Create: `/tmp/subtitle-reset-mkv-before.sha256`

**Interfaces:**
- Consumes: immutable archives, source URLs, and embedded subtitle streams.
- Produces: pristine Japanese sources, exact video-matched English ASS sources, and retained-MKV checksums.

- [ ] **Step 1: Hash every retained MKV**

Hash the 15 Bakemonogatari, 12 Erased, 12 Sonny Boy, 13 Wonder Egg Priority, and 51 Fullmetal Alchemist MKVs into `/tmp/subtitle-reset-mkv-before.sha256`. Exclude both Kokoro directories.

- [ ] **Step 2: Extract Japanese archives into show-specific temporary directories**

Use `unzip`, `unrar`, and `7z` without writing beside the MKVs. Download the Fullmetal Alchemist archive from the exact URL in `fullmetal-alchemist/source.txt`, then extract it under `/tmp/subtitle-reset/originals/fullmetal-alchemist`.

- [ ] **Step 3: Extract the correct embedded English dialogue tracks**

Use `ffmpeg -map 0:s:N -c:s copy` per MKV with these source tracks:

- Bakemonogatari: English `Coalgirls` (`0:s:0`).
- Erased: English `[Full]` (`0:s:1`).
- Sonny Boy: `Dialog - ENG` (`0:s:1`).
- Wonder Egg Priority: `Dialog - ENG` (`0:s:1`).
- Fullmetal Alchemist: `Full (FMA1394)` (`0:s:1`).

Write all extracted files under `/tmp/subtitle-reset/english/<show>/` using the matching video stem.

- [ ] **Step 4: Verify staged counts**

Expected Japanese/English episode pairs: Bakemonogatari 15, Erased 12, Sonny Boy 12, Wonder Egg Priority 13, Fullmetal Alchemist 51; total 103 pairs.

---

### Task 3: Build the one-off conservative transformer and its self-check

**Files:**
- Create: `/tmp/conservative_subtitle_reset.py`
- Create: `/tmp/test_conservative_subtitle_reset.py`

**Interfaces:**
- Consumes: source SRT/ASS files, per-episode affine timing parameters, and allowed ASS dialogue styles.
- Produces: source-faithful preview subtitles plus a machine-readable removal/timing report.

- [ ] **Step 1: Write the failing self-check**

Cover these guarantees with plain `assert` statements:

```python
assert transform_text(source_cue) == source_cue.text
assert transform_boundaries(source_cues) == source_cues
assert apply_timing(1000, scale=1.0, offset=850) == 1850
assert is_song('♪ opening lyric')
assert not is_song('普通の会話')
assert keep_ass_style('GJM_Overlap', {'GJM_Main', 'GJM_Overlap'})
assert not keep_ass_style('CicSigns', {'GJM_Main', 'GJM_Overlap'})
```

Also assert that ASS headers and style definitions remain byte-identical except the two Erased dialogue style definitions.

- [ ] **Step 2: Run the self-check and confirm it fails**

Run:

```sh
python3 /tmp/test_conservative_subtitle_reset.py
```

Expected: failure because the transformer does not yet exist.

- [ ] **Step 3: Implement the minimum transformer**

Use only Python's standard library. Preserve source cue sequence and text. Permit only:

- affine timestamp conversion `new_time = round(scale * old_time + offset)`;
- removal of cues containing song markers `♪` or `♫`;
- removal of ASS events whose source style is not in the explicit dialogue allowlist;
- removal of whole-cue descriptions only when source metadata/text unambiguously marks them non-dialogue;
- Erased `TEXT JPO` and `TEXT JPO (UP)` font changes to `Noto Sans CJK JP`, size `58`, bold, outline `4`, while preserving their alignment and margins.

English dialogue style allowlists:

- Bakemonogatari: `Default`, `Default - margin`.
- Erased: `GJM_Main`, `GJM_Overlap`.
- Sonny Boy: `Default`, `Overlap`, `Alt Style`.
- Wonder Egg Priority: `Default`, `Default - Top`, `Default - Brain`.
- Fullmetal Alchemist: `Dialogue`, `Dialogue Alt`.

Do not treat a style named `Overlap`, `GJM_Overlap`, `Alt Style`, or `Default - Top` as background chatter; these are ambiguous spoken dialogue and must remain.

- [ ] **Step 4: Run the self-check**

Run:

```sh
python3 /tmp/test_conservative_subtitle_reset.py
```

Expected: all assertions pass.

---

### Task 4: Recover timing-only transforms and generate previews

**Files:**
- Read: current Japanese subtitle files for the five retained shows.
- Create: `/tmp/subtitle-reset/preview/<show>/subs.jp|subs.ja/`
- Create: `/tmp/subtitle-reset/preview/<show>/subs.en/`
- Create: `/tmp/subtitle-reset/report.csv`

**Interfaces:**
- Consumes: pristine sources, current corrected timing as same-language anchors, and the transformer.
- Produces: complete source-faithful preview sets and an audit record.

- [ ] **Step 1: Recover timing from identical Japanese text anchors**

Match pristine and current Japanese cues using identical normalized Japanese text only—never English translation. Use medians from beginning, middle, and end anchors to determine whether each episode needs a constant offset or linear drift correction. Ignore mutated short-cue outliers. Stop on a discontinuity rather than inventing a piecewise correction.

- [ ] **Step 2: Record every timing transform**

Write `show,episode,scale,offset_ms,anchor_count,max_anchor_residual_ms` to `/tmp/subtitle-reset/report.csv`. Require multiple anchors from all three episode thirds and reject an episode whose residuals do not support a single constant/linear model.

- [ ] **Step 3: Generate Japanese previews**

Transform timestamps only, preserve original format (`.srt` for source SRT and `.ass` for Erased), remove approved non-dialogue cues, and use the matching human-readable video stem.

- [ ] **Step 4: Generate English previews**

Filter the freshly extracted video-matched ASS files by the explicit dialogue style allowlists. Do not change timestamps, text, or cue boundaries.

---

### Task 5: Verify previews before installation

**Files:**
- Read: `/tmp/subtitle-reset/preview/`
- Read: `/tmp/subtitle-reset/report.csv`

**Interfaces:**
- Consumes: generated previews and pristine sources.
- Produces: approval evidence for installation.

- [ ] **Step 1: Verify source fidelity**

For every file, assert that the output cue-text sequence equals the source sequence after subtracting only reported allowed removals. Assert no surviving cue was merged, split, reordered, duplicated, or text-edited.

- [ ] **Step 2: Verify English styles**

Assert every surviving English event uses its show's allowlisted dialogue style and every removed event uses a non-dialogue style. Preserve ambiguous overlap styles.

- [ ] **Step 3: Verify timing models**

Assert every Japanese output timestamp follows its episode's recorded affine transform. Reject negative, reversed, or out-of-video timestamps.

- [ ] **Step 4: Spot-check playback anchors**

Check beginning, middle, and end of every episode against the matching video. A stable residual is an offset; a growing residual is drift; a sudden discontinuity blocks installation for that episode.

- [ ] **Step 5: Parse every preview**

Run `ffprobe -v error` on all 206 subtitle files. Expected: no parse failures.

---

### Task 6: Install the verified reset and update mpv profiles

**Files:**
- Replace: local and dotfiles `subs.jp`/`subs.ja` and `subs.en` contents for five shows.
- Preserve: all `source.txt`, `torrent.txt`, `rename.sh`, and Sonny Boy `lyrics/` files.
- Modify: `/home/evakuator/dotfiles/configs/xdg/mpv/mpv.conf`

**Interfaces:**
- Consumes: verified previews.
- Produces: active source-faithful subtitle sets locally and in dotfiles.

- [ ] **Step 1: Replace subtitle directories from the preview**

Remove only the old active subtitle files, then copy the verified previews to both local show folders and matching dotfiles folders. Preserve Erased's existing `subs.ja` directory name; use `subs.jp` elsewhere.

- [ ] **Step 2: Remove font overrides from non-Erased profiles**

Delete `sub-font-size=38` from Bakemonogatari, Sonny Boy, Wonder Egg Priority, and Fullmetal Alchemist profiles. Keep the Erased override and `secondary-sub-pos=6` for all retained shows.

- [ ] **Step 3: Make track selection language-based where possible**

Keep the known Japanese audio IDs, set `slang=ja,en`, and use automatic primary/secondary selection for external `.ja.srt`/`.ja.ass` and `.en.ass` files. Avoid fixed subtitle IDs that depend on embedded-track counts.

---

### Task 7: Final verification and commit

**Files:**
- Read: all installed subtitles and retained MKVs.
- Commit: the complete dotfiles reset.

**Interfaces:**
- Consumes: installed subtitle sets and the pre-change checksum file.
- Produces: a verified Git commit and concise handoff.

- [ ] **Step 1: Verify counts, parsing, and mirrors**

Require 103 Japanese and 103 English active files. Require every local subtitle file to be byte-identical to its dotfiles mirror and every file to parse with `ffprobe`.

- [ ] **Step 2: Verify retained MKVs**

Run:

```sh
sha256sum --check /tmp/subtitle-reset-mkv-before.sha256
```

Expected: all 103 retained MKVs report `OK`.

- [ ] **Step 3: Verify mpv track selection**

For one episode per show, launch mpv headlessly with the show profile and confirm Japanese audio, Japanese primary subtitles, and English secondary subtitles are selected. Confirm only Erased has a show-specific font-size override.

- [ ] **Step 4: Inspect the complete Git diff**

Confirm the diff contains only the approved subtitle reset, Kokoro removal, obsolete audit removal, and mpv/torrent cleanup. Run `git diff --check`.

- [ ] **Step 5: Commit**

Stage only the approved paths and commit with:

```sh
git commit -m 'Reset anime subtitles to source-faithful cues'
```

