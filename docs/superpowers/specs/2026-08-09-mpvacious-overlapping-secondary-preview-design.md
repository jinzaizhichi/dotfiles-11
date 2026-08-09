# Overlapping Secondary Subtitle Preview

## Goal

Show the exact combined secondary subtitle text in the mpvacious OSD before
the user creates a card. Today the OSD shows only secondary cues observed so
far, while card creation later resolves every cue overlapping the selected
primary timing range from the full secondary track.

## Design

The subtitle observer will expose one operation that resolves secondary text
for the current selection. It will use the existing full-track cache first and
the existing observed-cue fallback when the cache is unavailable.

Both `collect_from_current()` and the OSD selection preview will use that same
operation. The OSD will replace its raw list of recorded secondary cues with
the single resolved string, so its preview matches the value exported to Anki.
Primary preview behavior remains unchanged.

No new overlap algorithm, configuration option, subprocess, or card-creation
work is introduced. Embedded-track loading remains asynchronous; opening or
updating the menu reads the latest available cache and otherwise preserves the
current observed-cue fallback.

## Verification

- An observer test proves the shared resolver prefers cached overlapping text.
- An observer test proves it falls back to observed secondary cues.
- The full test suite remains green.
- Manual verification selects one Japanese cue spanning multiple English cues
  and confirms the OSD preview matches the eventual Anki secondary field.
