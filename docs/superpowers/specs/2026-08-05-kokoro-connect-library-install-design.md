# Kokoro Connect subtitle library installation design

## Goal

Install the visually verified Timecraft Kokoro Connect subtitles into dotfiles and give the 13 local MKVs readable, title-based names.

## Naming

Use `Kokoro Connect - NN - Episode Title` as the shared basename for each MKV and its Japanese and English subtitle files. Episode titles come from the previously supplied release metadata.

## Dotfiles layout

Create `japanese/anime/subtitles/kokoro-connect/` containing:

- `subs.jp/` with the 13 verified Japanese SRT files.
- `subs.en/` with the 13 conservatively filtered English ASS files.
- `source.txt` with the Japanese and English Kitsunekko archive URLs.
- `torrent.txt` with the Timecraft RuTracker URL.
- `rename.sh` mapping all 13 original Timecraft filenames to the readable names. The script must be idempotent and refuse to overwrite existing files.

Add a `[kokoro-connect]` section to the global mpv configuration in dotfiles. It selects Japanese audio, searches `subs.jp` and `subs.en`, and prefers Japanese as primary with English secondary.

## Subtitle policy

Copy the currently verified files byte-for-byte. Do not merge, split, stretch, translate, restyle, or otherwise modify cues. The only subtitle changes in this operation are filenames and destination paths.

## Safety and verification

Record MKV hashes before renaming and confirm the same hashes afterward. Verify that subtitle hashes are unchanged by renaming and copying, that all expected basenames match, that `rename.sh` passes `sh -n`, and that mpv loads one renamed episode with both external subtitles.
