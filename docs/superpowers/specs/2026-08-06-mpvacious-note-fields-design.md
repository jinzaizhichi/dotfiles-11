# Mpvacious note-field fixes

## Goal

New notes updated by mpvacious must retain one highlighted Japanese sentence and include every secondary subtitle cue that overlaps the mined primary cue.

Existing Anki notes are out of scope.

## Design

- Pin `japanese/setup.sh` to a tested commit in `kuator/mpvacious` containing the fixes.
- Select secondary cues by strict time overlap and join them in subtitle order with spaces.
- When joining sentence fields, compare text after removing HTML, normalizing whitespace, and treating Japanese and typographic quotation marks as equivalent. If the normalized sentences match, retain Yomitan's existing highlighted field instead of appending mpvacious's variant.
- Do not broadly discard punctuation: only whitespace and quote representation are normalized.

## Verification

- A regression test models note `1786041864662`: the Japanese variants compare as equivalent and do not duplicate.
- A cue-alignment test expects both English cues: `But these are a girl's... A woman's b-words?`
- Bootstrap tests verify the fork and exact commit are installed on a fresh machine.
