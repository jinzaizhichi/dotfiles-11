# Overlapping Secondary Subtitle Preview

## Goal

Show the exact combined secondary subtitle text in the mpvacious OSD before
the user creates a card. Today the OSD shows only secondary cues observed so
far, while card creation later resolves every cue overlapping the selected
primary timing range from the full secondary track.

## Design

This is separate from the OSD-wrapping pull request. Ren's merged `collector`
and `sub_list` implementation remains authoritative for joining and
deduplicating observed cues. The omitted full-track cache will be rewritten as
an isolated look-ahead extension and must consume the same selected `Subtitle`
timing window as `sub_list.get_overlapping_text()`.

The subtitle observer will expose one operation that resolves secondary text
for the current selection. It will use the full-track cache first and the
merged observed-cue implementation when the cache is unavailable.

Both `collect_from_current()` and the OSD selection preview will use that same
operation. The OSD will replace its raw list of recorded secondary cues with
the single resolved string, so its preview matches the value exported to Anki.
Primary preview behavior remains unchanged.

No new overlap algorithm, configuration option, or card-creation path is
introduced. Embedded-track loading remains asynchronous; opening or updating
the menu reads the latest available cache and otherwise preserves the merged
observed-cue fallback.

The work will be proposed as a draft upstream pull request. Its description
will explain the concrete Japanese-cue/English-cues scenario, state that the
full-track behavior is the part omitted from PR #173, show the fallback when a
track cannot be loaded, and explicitly ask maintainers whether the behavior
belongs upstream and whether it should be configurable. The old `4b95adb`
commit will not be reused as the PR implementation.

## Verification

- Full-track tests prove the local extension accepts the merged `Subtitle`
  timing-window interface.
- Observer tests prove the shared resolver prefers cached overlapping text and
  falls back to `sub_list.get_overlapping_text()`.
- The full test suite remains green.
- Manual verification selects one Japanese cue spanning multiple English cues
  and confirms the OSD preview matches the eventual Anki secondary field.
