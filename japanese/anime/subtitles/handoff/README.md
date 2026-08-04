# Anime subtitle processing handoff

Use this document as context when processing another show.

## Goal

Prepare subtitles for Japanese sentence mining:

- Japanese is the primary subtitle.
- Clean English dialogue is the secondary subtitle.
- Do not modify, remux, rename streams in, or otherwise mutate MKV contents.
- Subtitle filenames should share the video's human-readable stem.
- Keep Japanese and English cue segmentation aligned whenever possible.
- Remove signs, songs, credits, typesetting, and other non-dialogue English events.
- Remove adjacent repeated English text.
- Avoid subtitle cues shorter than 400 ms.
- Store finished subtitles and the original download URL in dotfiles.
- Use global show-specific profiles in `~/.config/mpv/mpv.conf`; do not create folder-local mpv configs.

Never run a local Whisper/Vibe model or install an AI model. In particular, do not access or run:

`~/.local/share/github.com.thewh1teagle.vibe/ggml-large-v3-turbo.bin`

## Preferred directory structure

```text
Show directory/
├── Show - 01.mkv
├── subs.jp/
│   └── Show - 01.ja.ass
└── subs.en/
    └── Show - 01.en.ass
```

Erased currently uses `subs.ja` instead of `subs.jp`; preserve that existing structure unless explicitly asked to rename it.

Dotfiles should mirror the subtitle structure:

```text
~/dotfiles/japanese/anime/subtitles/<show>/
├── source.txt
├── subs.jp/  # or the show's existing subs.ja
└── subs.en/
```

`source.txt` contains the exact original subtitle download URL and nothing else unless multiple sources were actually used.

## Workflow for a new show

1. Inventory MKVs with `rg --files` or `find`. Use `ffprobe`/`mkvmerge -J` to identify Japanese audio and embedded English dialogue tracks.
2. Download the Japanese subtitle archive with `wget` without installing anything.
3. Extract into `/tmp`; never overwrite the MKVs.
4. Match episodes by episode number, not merely lexicographic coincidence.
5. Check synchronization at the beginning, middle, and end of every episode.
   - A stable difference is a constant offset.
   - A growing difference is drift and needs a linear correction.
   - A sudden discontinuity indicates a different cut; identify the missing/extra segment rather than forcing one global offset.
6. Extract embedded English subtitles without remuxing the video.
7. Keep only dialogue styles. Exclude signs, songs, OP/ED, titles, credits, drawings (`\p1` etc.), and empty events.
8. Remove exact duplicate events and adjacent repeated text.
9. Align English and Japanese in both directions, as described below.
10. Normalize extremely short paired cues, as described below.
11. Write styled ASS files.
12. Copy the finished subtitles and `source.txt` to dotfiles.
13. Add a show-specific global mpv profile and verify actual track selection.
14. Run the complete verification checklist before claiming completion.

## Bidirectional cue alignment

The old alignment bug assigned every English cue to only the Japanese cue with the greatest overlap. This caused a combined English cue such as:

```text
Morning, Taichi. Still sleepy?
```

to be attached only to `おはよう 太一`, leaving `まだ眠そうだね` without a visible counterpart.

Apply alignment per local overlapping block:

- Several English cues overlapping one Japanese cue: merge their unique text in chronological order.
- One English cue overlapping several Japanese cues: split it at sentence boundaries and distribute consecutive fragments across the Japanese timings.
- More English sentence fragments than Japanese cues: group consecutive fragments proportionally using the Japanese cue durations.
- Fewer English fragments than Japanese cues: keep one English cue and extend it from the first matched Japanese start to the last matched Japanese end. Do not duplicate the English or merge the Japanese cues.
- Preserve chronological order and ASS inline formatting.
- Never duplicate the full combined English text across several Japanese cues.

Regression examples:

```text
Japanese 1: おはよう 太一  -> English: Morning, Taichi.
Japanese 2: まだ眠そうだね -> English: Still sleepy?
```

```text
Japanese 1: えっ ああ… -> English: Huh? Oh.
Japanese 2: ありがとう   -> English: Thanks.
```

Reusable implementation and regression tests are included beside this document:

- `sonny_process.py`: parsing, alignment, deduplication, ASS writing, and short-cue normalization.
- `test_bidirectional_alignment.py`: eleven dependency-free regression tests.
- `resegment_finished_shows.py`: the exact six-show regeneration and coverage-audit driver used in this session.

Run the tests before reuse:

```sh
python3 test_bidirectional_alignment.py
```

`resegment_finished_shows.py` intentionally records the exact source and destination paths used for the six completed shows. For a new show, add its source mapping and provide its extracted English source; previews are written under `/tmp/coverage-preview` before installation.

## Short-cue normalization

Use 400 ms as the minimum duration:

- If a cue under 400 ms has a suitable adjacent cue within 500 ms, merge both Japanese cues and both English counterparts over the combined timing.
- Prefer a paired neighbor and then the nearest neighbor.
- If there is no suitable nearby cue, extend the Japanese and English cue together to 400 ms without overlapping another cue.
- Preserve the complete Japanese and English text stream.
- Recheck that no cue has an invalid or sub-400 ms duration.

Example:

```text
Before:
07:47.84–07:47.97  あっ？          / Huh?
07:47.97–07:49.59  いや おやすみ / Nothing. Good night.

After:
07:47.84–07:49.59  あっ？ + いや おやすみ
                     Huh? + Nothing. Good night.
```

## Styling

Current generated ASS styles:

```text
Japanese: Noto Sans CJK JP, size 58, bold, outline 4
English:  Noto Sans, size 46, bold, outline 3
```

The global mpv profiles additionally use `sub-font-size=38` and `secondary-sub-pos=6`. Japanese should be primary; English should appear lower as secondary.

## Missing Japanese dialogue

Before translating anything, search alternate releases on Kitsunekko and Jimaku and compare the actual cue text—not just filenames or claimed sync.

If every Japanese source omits dialogue present in the target cut:

- Ask for approval before translating the English counterpart.
- Translate only the missing spoken dialogue.
- Reuse the English cue timings so segmentation remains one-to-one.
- Mark the translated portion as unofficial in the handoff.
- Do not fabricate Japanese from signs or non-dialogue descriptions.

Kokoro Connect episode 6 has an approved unofficial translation for 30 missing opening cues from `00:14.11` through `01:31.44`. Sourced Japanese resumes at `03:03.95`.

The Japanese source for episode 6 also contains a 90.13-second segment absent from the local video after `03:43`; four music-marker cues were removed and later Japanese cues were shifted by `-90.130s`. Episode 14 uses the opposite cut arrangement: Japanese cues from `01:32.560` were shifted by `+89.130s` to match the local video.

## Verification checklist

Run fresh checks on the actual destination files:

- Expected episode/file counts match.
- Every ASS parses with `ffprobe`.
- Every cue has `end > start`.
- No Japanese or English cue is shorter than 400 ms.
- No adjacent English cues repeat the same normalized text.
- Japanese/English text content is preserved through merges.
- Local subtitle files are byte-identical to their dotfiles mirrors.
- `mpv --profile=<show>` selects Japanese audio, Japanese primary subtitles, and English secondary subtitles.
- MKV checksums/contents were not changed; subtitle work must remain external.

## Completed shows and sources

### Bakemonogatari (15 episodes)

- Dotfiles: `~/dotfiles/japanese/anime/subtitles/monogatari/bakemonogatari`
- Source: `https://kitsunekko.net/subtitles/japanese/Bakemonogatari/Bakemonogatari%20(01-15)%20(Webrip).zip`
- Profile: `[bakemonogatari]`
- No current local video folder was found during the final normalization; dotfiles were updated.

### Erased (12 episodes)

- Local: `~/Shared/[Judas] Boku Dake ga Inai Machi (Erased) (Season 1) [BD 1080p][HEVC x265 10bit][Dual-Audio][Eng-Subs]`
- Dotfiles: `~/dotfiles/japanese/anime/subtitles/erased`
- Source: `https://kitsunekko.net/subtitles/japanese/Boku_Dake_Ga_Inai_Machi/[Kamigami]%20Boku%20dake%20ga%20Inai%20Machi%20(Synced%20for%20HorribleSubs).rar`
- Profile: `[erased]`
- Video/subtitle filenames are now `Erased - NN...`; the parent directory still contains `[Judas]`.

### Sonny Boy (12 episodes)

- Local: `~/Shared/Sonny Boy [BD][1080p][HEVC 10bit x265][Dual Audio][Tenrai-Sensei]`
- Dotfiles: `~/dotfiles/japanese/anime/subtitles/sonny-boy`
- Source: `https://kitsunekko.net/subtitles/japanese/Sonny%20Boy/SonnyBoy.zip`
- Profile: `[sonny-boy]`

### Kokoro Connect (17 episodes)

- Local: `~/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)`
- Dotfiles: `~/dotfiles/japanese/anime/subtitles/kokoro-connect`
- Source: `https://kitsunekko.net/subtitles/japanese/Kokoro%20Connect/Kokoro%20Connect%20%2801-17%29.zip`
- Profile: `[kokoro-connect]`
- Current filenames are `Kokoro Connect - NN...`.

### Wonder Egg Priority (12 episodes + special)

- Local: `~/Shared/Wonder Egg Priority [BD][1080p][HEVC 10bit x265][Dual Audio][Tenrai-Sensei]`
- Dotfiles: `~/dotfiles/japanese/anime/subtitles/wonder-egg-priority`
- Source: `https://kitsunekko.net/subtitles/japanese/Wonder%20Egg%20Priority/[Nekomoe%20kissaten]%20WONDER%20EGG%20PRIORITY%20(1-13)[BDRip%201080p%20HEVC-10bit%20FLAC].JPSC.zip`
- Profile: `[wonder-egg-priority]`
- Episodes 01–12 are in the main folder; source episode 13 maps to `Specials/Wonder Egg Priority - S00E01 - My Priority.mkv`.
- The special has its own `Specials/subs.jp` and `Specials/subs.en` folders for mpv autoloading.
- Source timing differed by only 10–70 ms per episode, with no measurable drift or cut mismatch.

### Fullmetal Alchemist (2003) (51 episodes)

- Local: `~/Shared/Fullmetal Alchemist`
- Dotfiles: `~/dotfiles/japanese/anime/subtitles/fullmetal-alchemist`
- Source: `https://kitsunekko.net/subtitles/japanese/Fullmetal%20Alchemist/Freshly%20ripped%20from%20netflix%20timed%20to%20philosophy%20raws.7z`
- Profile: `[fullmetal-alchemist]`
- Per-episode constant offsets ranged from -472 ms to +68 ms; beginning/middle/end checks found no measurable progressive drift or cut mismatch.
- Two spoken English cues have no separate Japanese source cue: episode 12 `What?` and episode 17 `We got him, all right!`; both remain as English-only dialogue.

## Current verified state

- 120 episodes/specials processed across six shows.
- 240 Japanese/English dotfiles subtitle files verified.
- The latest coverage pass extended 3,905 indivisible English cues across every Japanese cue they overlap, without duplicating English or merging Japanese cues.
- The six shows contain 38,209 cleaned English cues after resegmentation.
- 22 extremely short logical cue instances were normalized.
- No cue is under 400 ms.
- No adjacent English duplicate text was found.
- A semantic counterpart review fixed 65 Japanese rows whose matching English cue was nearby but did not overlap. The remaining suspected genuine omissions are listed in `missing-english-counterparts.csv`.
- Erased, Sonny Boy, Kokoro Connect, Wonder Egg Priority, and Fullmetal Alchemist local copies match dotfiles.
- mpv selected Japanese primary and English secondary for all five locally available shows.
- The MKVs were not modified.

A temporary rollback of the English subtitles exists at `/tmp/subtitles-before-bidirectional-20260804`, but `/tmp` is not durable and may be cleared on reboot.
