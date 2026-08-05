# Conservative Anime Subtitle Reset Design

## Goal

Reset the subtitle collection to source-faithful Japanese and English tracks while retaining only mechanical synchronization fixes and clearly safe mining conveniences.

## Scope

Rebuild these shows from their original subtitle sources:

- Bakemonogatari
- Erased
- Sonny Boy
- Wonder Egg Priority
- Fullmetal Alchemist (2003)

Remove the obsolete local `/home/evakuator/Shared/[DB]Kokoro Connect_-_(Dual Audio_10bit_BD1080p_x265)` directory through the desktop trash mechanism, remove its dotfiles subtitle directory and mpv profile, and remove stale Kokoro references from subtitle reports. Leave `/home/evakuator/Shared/[Timecraft & NASTR] Kokoro Connect` untouched.

## Source-Faithful Processing

For Japanese and English subtitles:

- Restore text, cue order, cue boundaries, and styles from the original source files or embedded tracks.
- Apply only timing corrections needed for the matching local video: constant offset or measured linear drift.
- Do not merge, split, stretch, duplicate, translate, or semantically rewrite dialogue cues.
- Do not normalize short cue duration.
- Do not alter cue timing merely to make Japanese and English overlap.

The active tracks may remove only:

- songs and lyrics;
- signs, credits, typesetting, animation numbers, and other non-dialogue events;
- background chatter explicitly identified by source style or layer metadata.

Ambiguous overlapping dialogue remains unchanged. Any future removal that requires interpreting the spoken meaning requires manual semantic review.

## Styling

Preserve original subtitle fonts and styles for every show except Erased. Retain Erased's approved larger Japanese font and thicker outline. Do not add show-specific font overrides elsewhere.

## mpvacious

Keep the existing local mpvacious secondary-line deduplication patch. It removes repeated English lines when several cues are selected for a card, so subtitle files themselves do not need destructive deduplication or cross-language resegmentation.

## Retained Quality-of-Life Features

- External subtitles; never modify or remux retained MKVs.
- Separate Japanese and English subtitle directories.
- Human-readable video/subtitle stems and reusable rename scripts.
- Global show-specific mpv profiles selecting Japanese audio, Japanese primary subtitles, and English secondary subtitles.
- English secondary subtitle positioning that avoids the Japanese text.
- Original subtitle source links and torrent links.
- Unmodified original subtitle archives where available.
- Separate Sonny Boy lyric text files while song cues remain absent from active subtitles.

## Removed Processing

Remove or retire generated reports and helpers whose purpose is semantic pairing, cue splitting/merging, short-cue normalization, or subtitle-level English deduplication. Git history remains the recovery mechanism for the discarded processed subtitle set.

## Verification

For every rebuilt episode:

- Compare dialogue text and cue boundaries against the source after accounting for explicitly removed event categories.
- Confirm timing corrections do not alter text or segmentation.
- Confirm removed cues belong only to allowed categories.
- Confirm fonts/styles match the source except for Erased.
- Confirm local and dotfiles copies match.
- Confirm mpv selects Japanese primary and English secondary tracks.
- Confirm retained MKV checksums are unchanged.

