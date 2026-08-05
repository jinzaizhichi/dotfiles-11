# Kokoro Connect Subtitle Library Installation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the 13 Timecraft MKVs and matching verified subtitles to readable episode-title names, then preserve the subtitles and recovery metadata in dotfiles.

**Architecture:** Use one explicit, idempotent POSIX shell rename map as the source of truth. Rename the local MKVs and subtitle files without rewriting their contents, copy the subtitle tree and metadata into dotfiles, and add one mpv profile following the existing show conventions.

**Tech Stack:** POSIX shell, coreutils, mpv configuration, Git

## Global Constraints

- Do not merge, split, stretch, translate, restyle, or otherwise modify subtitle cues.
- Use `Kokoro Connect - NN - Episode Title` as the basename for each MKV and subtitle pair.
- Preserve all MKV and subtitle bytes; only paths and filenames may change.
- `rename.sh` must be idempotent and must refuse to overwrite an existing target.

---

### Task 1: Build and test the rename map

**Files:**
- Create: `/tmp/kokoro-connect-rename.sh`
- Test: `/tmp/test-kokoro-connect-rename.sh`

**Interfaces:**
- Consumes: a root directory containing the original 13 Timecraft MKV basenames.
- Produces: `rename.sh [root]`, renaming each original file to its titled basename and exiting nonzero on missing or conflicting files.

- [ ] **Step 1: Write the failing fixture test**

Create a temporary directory containing the 13 original basenames, invoke the not-yet-created rename script, and assert that these 13 targets exist:

```text
Kokoro Connect - 01 - A Story That Had Already Begun Before Anyone Realized It.mkv
Kokoro Connect - 02 - Some Fascinating Humans.mkv
Kokoro Connect - 03 - Jobber and Low Blow.mkv
Kokoro Connect - 04 - Twin Feelings.mkv
Kokoro Connect - 05 - A Confession and Death.mkv
Kokoro Connect - 06 - A Story That Continued Before Anyone Realized It.mkv
Kokoro Connect - 07 - Falling Apart.mkv
Kokoro Connect - 08 - And Then There Were None.mkv
Kokoro Connect - 09 - Can't Stop, Can't Stop, Can't Stop.mkv
Kokoro Connect - 10 - Putting into Words.mkv
Kokoro Connect - 11 - A Story That Began as We Realized It.mkv
Kokoro Connect - 12 - Into a Snow City.mkv
Kokoro Connect - 13 - As Long as the Five of Us Are Together.mkv
```

- [ ] **Step 2: Verify the test fails**

Run: `sh /tmp/test-kokoro-connect-rename.sh`

Expected: nonzero exit because `/tmp/kokoro-connect-rename.sh` does not exist.

- [ ] **Step 3: Implement the minimum rename script**

Reuse the established `rename_file()` implementation from `japanese/anime/subtitles/erased/rename.sh` and add the 13 explicit Timecraft-to-title mappings.

- [ ] **Step 4: Verify rename behavior**

Run the fixture test twice. The first run must rename all files; the second must succeed without changes. Add a conflicting source and target fixture and require a nonzero exit with `Refusing to overwrite`.

---

### Task 2: Rename local files without changing bytes

**Files:**
- Rename: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/*.mkv`
- Rename: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/subs.jp/*.ja.srt`
- Rename: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect/subs.en/*.en.ass`

**Interfaces:**
- Consumes: the tested 13-title mapping from Task 1.
- Produces: 13 MKV/JP/EN basename triples.

- [ ] **Step 1: Hash current files**

Save sorted SHA-256 manifests for all MKVs, Japanese subtitles, and English subtitles under `/tmp/kokoro-connect-install/`.

- [ ] **Step 2: Rename the MKVs**

Run: `sh /tmp/kokoro-connect-rename.sh '/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect'`

Expected: 13 rename messages and exit zero.

- [ ] **Step 3: Rename matching subtitles**

Apply the same episode-title map to `subs.jp` and `subs.en`, retaining `.ja.srt` and `.en.ass` suffixes.

- [ ] **Step 4: Verify bytes and basename triples**

Regenerate content-only hashes and require them to match the pre-rename manifests. Require exactly 13 complete MKV/JP/EN basename triples.

---

### Task 3: Install the show in dotfiles

**Files:**
- Create: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/rename.sh`
- Create: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/source.txt`
- Create: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/torrent.txt`
- Create: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/subs.jp/*.ja.srt`
- Create: `/home/evakuator/dotfiles/japanese/anime/subtitles/kokoro-connect/subs.en/*.en.ass`
- Modify: `/home/evakuator/dotfiles/configs/xdg/mpv/mpv.conf`

**Interfaces:**
- Consumes: the renamed, verified local subtitle tree from Task 2.
- Produces: a reproducible dotfiles show folder and `[kokoro-connect]` mpv profile.

- [ ] **Step 1: Copy subtitles and rename script**

Copy the two subtitle directories byte-for-byte and install the tested rename script as executable `rename.sh`.

- [ ] **Step 2: Add provenance**

Write `source.txt` with:

```text
https://kitsunekko.net/subtitles/japanese/Kokoro%20Connect/Kokoro%20Connect%20(01-17).zip
https://kitsunekko.net/subtitles/Kokoro%20Connect/[HorribleSubs]_Kokoro_Connect_01-13.rar
```

Write `torrent.txt` with:

```text
https://rutracker.org/forum/viewtopic.php?t=4122331
```

- [ ] **Step 3: Add the mpv profile**

Append this profile to the managed mpv configuration:

```ini
[kokoro-connect]
aid=2
sub-auto=fuzzy
sub-file-paths=subs.jp:subs.en
slang=ja,en
sid=auto
secondary-sid=auto
secondary-sub-pos=6

# mpv --profile=kokoro-connect 'Kokoro Connect - 01 - A Story That Had Already Begun Before Anyone Realized It.mkv'
```

- [ ] **Step 4: Verify installed artifacts**

Run `sh -n` on `rename.sh`, compare local and dotfiles subtitle SHA-256 manifests, and run the fixture rename test against the installed script.

- [ ] **Step 5: Smoke-test mpv**

Run mpv headlessly for one frame with `--profile=kokoro-connect` on episode 1 and require both external subtitle files to load without errors.

- [ ] **Step 6: Commit**

Stage only `japanese/anime/subtitles/kokoro-connect/` and `configs/xdg/mpv/mpv.conf`, then commit with `feat: add Kokoro Connect subtitles`.
