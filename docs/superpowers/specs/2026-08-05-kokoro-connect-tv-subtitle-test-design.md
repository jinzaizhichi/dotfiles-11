# Kokoro Connect TV Subtitle Test Design

## Goal

Prepare conservative external Japanese and English subtitles for the 13-episode Timecraft/NASTR HDTV release without modifying or renaming its MKV files.

## Sources

- Japanese: `https://kitsunekko.net/subtitles/japanese/Kokoro%20Connect/Kokoro%20Connect%20%2801-17%29.zip`, episodes 1–13 only.
- English: `https://kitsunekko.net/subtitles/Kokoro%20Connect/[HorribleSubs]_Kokoro_Connect_01-13.rar`.
- Video: `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect`, 13 HorribleSubs-derived 720p TV episodes, downloaded from `https://rutracker.org/forum/viewtopic.php?t=4122331`.

## Processing

- Keep the current MKV filenames and never modify or remux the MKVs.
- Use matching external files under `subs.jp/` and `subs.en/`.
- Apply no timing correction: semantically matching cues sampled from the beginning, middle, and end of all 13 episodes agree within approximately one video frame and show no growing residual.
- Preserve dialogue text, order, timing, and cue boundaries.
- Japanese: remove cues containing song markers and cues consisting solely of sound descriptions.
- English: keep the `CRKokoro` dialogue style unchanged; remove all sign, episode-title, and typesetting styles.
- Keep ambiguous simultaneous or background dialogue because the Japanese SRT source has no reliable style/layer metadata for distinguishing it.
- Do not merge, split, stretch, translate, deduplicate, or align cues across languages.

## Trial Scope

- Install the generated subtitles beside the downloaded videos only.
- Do not add Kokoro Connect back to dotfiles, add an mpv profile, or rename files until the user tests episodes 1, 6, and 13.
- Preserve both downloaded subtitle archives in `/tmp`; no permanent helper script is required.

## Verification

- Require exactly 13 Japanese and 13 English outputs.
- Assert every surviving cue is source-identical in text, timing, order, and boundaries.
- Assert removed cues belong only to the approved categories.
- Parse all 26 outputs with `ffprobe`.
- Hash all 13 MKVs before and after installation and require identical checksums.
