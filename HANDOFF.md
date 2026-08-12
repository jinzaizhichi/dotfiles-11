# Handoff

## Continuation guidance

Treat repository state as authoritative if it conflicts with this file. Inspect
status/diffs before editing, preserve unrelated changes, and do not repeat
completed investigation unless current state contradicts this handoff. Do not
commit or push root dotfiles unless explicitly requested. Git identity for this
work is `kuator <kuator578@gmail.com>`; the global config currently incorrectly
contains `evakuator` with an empty email, so set author and committer explicitly
before future commits.

## Current objective

Finish live/manual verification of the updated mpvacious PRs, especially PR
#180's safeguard against overwriting one unrelated Anki note. Then finish the
pending Ghostty visual check and review of the uncommitted subtitle-sync
bootstrap. No further implementation was requested after this handoff update.

## mpvacious PR #180: implemented and pushed

- The `シカト`/`貸す` hybrid exposed a gap: #180 only compared multiple recent
  notes to each other. A single recent note, selected note, or automatic
  new-note update could overwrite unrelated sentence/media fields without a
  warning.
- The guard now lives at the shared `note_exporter.update_notes` boundary, so it
  covers automatic new-note checks, last-note updates, selected-note updates,
  normal updates, and overwrites.
- Stored `SentKanji` is compared with the current primary subtitle after HTML,
  whitespace, supported quote/entity, and case normalization. Either text may
  contain the other, preserving intended highlighted/expanded-sentence updates.
  Empty current subtitle behavior is unchanged because users may be adding
  media to manually transcribed/image-subtitle cards.
- An unrelated single note shows a centered high-priority prompt:
  `The target note's SentKanji does not match the current subtitle.` The safe
  default `No` is blue. Left selects `Yes`, Right selects `No`, Enter activates
  the blue choice, explicit `y`/`n` work immediately, and the 10-second timeout
  cancels. This follows mpvacious's existing blue-selection/Enter convention.
- The regression test uses the exact failure shape: stored
  `そのメモ ちょっと<b>貸して</b>みろよ` versus current
  `無視された 小学生女子に シカトされた`. It tests default-Enter
  cancellation, navigation, explicit shortcuts, and existing multi-note flow.
- `luajit tests/run.lua` reports `ALL TESTS PASSED`; `git diff --check` and Lua
  bytecode loading passed. Live mpv interaction is still pending.
- Known review point: in the existing multi-note mismatch case, accepting the
  first “notes differ from each other” prompt calls the shared guard. If older
  selected notes also differ from the current subtitle, it can legitimately
  show a second confirmation. The standalone test stubs `update_notes` at the
  first prompt and therefore does not exercise this double-prompt path. Decide
  from live testing whether the second confirmation is useful or excessive;
  do not change it speculatively.
- PR #180 is OPEN, non-draft, CLEAN at
  `4b76c0494a177e54600c043053ba252ae8cc7332` (`fix: confirm unrelated
  single note updates`) on `kuator:fix/confirm-mismatched-recent-notes`.
  GitHub attributes both author and committer to
  `kuator <kuator578@gmail.com>`. The prior bad-metadata commit `4946241` was
  safely replaced with `--force-with-lease`.

Relevant file: `configs/xdg/mpv/scripts/mpvacious/mpvacious/anki/note_exporter.lua`.

## mpvacious combined checkout / PR #177

- Live nested checkout `configs/xdg/mpv/scripts/mpvacious` is clean on local
  `master` at `15ce65e0ee7b1e1274b24f07815801f0a08d3e6e`, nine commits ahead of
  `origin/master` (`98a29fa`). It combines PR #177 through `81ca880`, original
  #180 at `18d7776`, and the corrected local equivalent of the new #180 commit
  at `15ce65e`. Do not push this combined `master`.
- Local `pr-180` is the actual PR head `4b76c04`. PR #177 was last checked
  OPEN/DRAFT/CLEAN at `81ca8809fefe2a5249861ffcef597a641c8bee0d`.
- #177 retains forward `sub-step +1` discovery only. Secondary overlap requires
  75% when the shorter interval is under one second and 50% otherwise; a cue may
  pass against the combined primary window or a clipped individual primary cue.
  Full-track/ffmpeg discovery remains rejected because embedded subtitle
  prefetch in mpv is limited.
- Earlier automated #177 and combined suites passed, and real-mpv probes verified
  forward discovery for external and embedded subtitles. Required Bakemonogatari
  mining/OSD verification is incomplete; keep #177 draft until it passes.

Relevant modules: `mpvacious/subtitles/observer.lua`,
`mpvacious/subtitles/sub_list.lua`, `mpvacious/main.lua`, and
`mpvacious/anki/note_exporter.lua`.

## Live Anki repairs completed

- Read-only audit found exactly 3 of 424 `Japanese sentences` notes without
  `<b>...</b>` in `SentKanji`; the other 421 were valid.
- Repaired highlighting:
  - `1786373831833`: `お前の<b>力に なれる</b>かもしれないと思って`
  - `1786373936153`: `30過ぎの <b>年季の入った</b>中年だからな`
- Hybrid note `1786472440491` was restored as the intended `貸す` card:
  `そのメモ ちょっと<b>貸して</b>みろよ`, English corrected to
  `Let me take a look at that memo.`, timestamp set to Bakemonogatari EP03
  `18m44s686ms`, sentence audio/image cleared, and tag `needs-media` added. Its
  complete existing `貸す` definitions, furigana, pitch, frequencies, and vocab
  audio were preserved. User will add sentence media later.
- Added `シカト` note `1786516492059` with
  `無視された 小学生女子に <b>シカトされた</b>`, matching furigana,
  English, existing subtitle audio/image at EP03 `18m56s969ms`, Jitendex
  definition, and JPDB/CC100 frequencies.
- Verified live Anki state after writes: 425 notes total, `missingBold: 0`,
  `emptyBold: 0`. Writes used AnkiConnect, not direct SQLite mutation.
- No repository files were changed for these repairs.

## Japanese Sentences/Yomitan maintained state

- Installed model retains upstream fields/cards plus local `VocabFreq` after
  `VocabPitchNum`; Recognition/Production answers render compact JPDB/CC100
  chips. Updater pin: `acc6d71d7fb0e9fc7f8cf286b813a128ad3d0c84`.
- Both Yomitan formats map `VocabDef` to `{glossary}` and `VocabFreq` to
  `{frequencies}`. Existing frequency backfill remains 337 exact matches and 9
  deliberately unmatched values; do not recreate the deleted one-off tool.
- Maintained template behavior includes raw `VocabDef`, Recognition image below
  the sentence/expanded on mobile, compact purple dictionary pills, and visible
  Jitendex primary marker metadata. User already confirmed new mining stores
  `VocabFreq` and the Anki editor uses the intended Noto font.
- Tests previously passed: `./tests/update-japanese-sentences.sh`, shell syntax,
  Yomitan JSON assertions, and relevant `git diff --check`.
- Pending manual check: Recognition/Production frequency chip comfort and image
  layout on desktop/mobile.

Relevant files: `scripts/optional/japanese/update-japanese-sentences.sh`,
`tests/update-japanese-sentences.sh`, `japanese/yomitan/settings.json`, and the
Japanese section of `README.md`.

## Ghostty/fontconfig

- Implemented chain: `UbuntuMono Nerd Font`, then `Noto Sans Mono CJK JP` in
  `configs/xdg/ghostty/config`. Global fontconfig now appends unconditional Noto
  fallback and uses weak generic monospace bindings; Japanese-language and Arial
  Japanese fallbacks remain strong so Anki does not regress to Takao.
- Automated face selection confirmed Latin/Nerd glyphs use UbuntuMono Nerd Font
  and Japanese uses Noto Sans Mono CJK JP. `ghostty +validate-config` and
  `git diff --check` passed. Visual verification after Ghostty restart remains
  pending.
- Preserve font size `11`, nonblinking block cursor, shell-integration cursor
  suppression, and `Ctrl+[` mapping.

## Subtitle-sync bootstrap

- Implemented but uncommitted: `scripts/bootstrap/install-subtitle-sync.sh`,
  called by `scripts/setup.sh`, installs ffsubsync `0.4.31`, alass-cli `2.0.0`,
  and autosubsync-mpv commit
  `a6dc1bbf86d82d001b34c6b223d1f82ee3d7b2cc` reproducibly.
- Real initial/idempotent installs, pins/post-install checks, shell syntax,
  targeted simulated Ubuntu 24.04 Cinnamon/26.04 KDE assertions, Lua loading,
  and real versions passed.
- Full `./tests/bootstrap.sh` still fails only because the preserved `.zshrc`
  contains `mise activate`: `Mise activation belongs in the inherited profile
  PATH`. This is unrelated; do not fix it as subtitle-sync work. Ignore the
  unrelated `uv tool list` warning about a missing ruff environment.

## Personal note created outside this repository

- Created `/home/evakuator/zk/japanese/anki_deck_reset_urge.md`, titled
  `When I Want to Delete My Anki Deck`, for perfectionism/OCD-driven urges to
  reset the collection and the alienation felt after weeks/months away. It
  emphasizes that familiarity returns through ordinary contact, not deletion.

## Exact next steps

1. Restart/reload mpv and live-test PR #180 for a single unrelated note and the
   existing multi-note case: safe blue `No`, Left/Right selection, Enter,
   explicit `y`/`n`, 10-second timeout, centered/high-priority OSD, and no media
   creation before confirmation. Specifically observe whether accepting a
   multi-note mismatch produces the possible second shared-guard prompt and
   whether that interaction should be consolidated.
2. Complete #177 Bakemonogatari regression mining. Positive primary cues
   `20:45.702–20:48.205` and `20:48.789–20:52.125` must export both Coalgirls
   sentences in order. English cue `20:43.200–20:47.740` overlaps 44.9% of the
   combined window but 81.4% of the first primary cue. Negative cases
   `うん 好きかな` (`12:41.594–12:43.179`) and `くっ`
   (`12:56.358–12:57.193`) must omit their incidental English. Check OSD
   numbering/wrapping; horizontal wrapping exists, vertical scrolling does not.
3. Reload/restart Ghostty and visually confirm `Aa0`, Nerd glyph U+E725, and
   `日本語`. If wrong, run `ghostty +show-face --string='Aa0 日本語 '` and
   preserve the working Anki Arial fallback.
4. Preview Japanese Sentences Recognition/Production answers on desktop/mobile.
5. Review the subtitle-sync bootstrap diff; rerun targeted checks only if it
   changes. Recheck GitHub PR state before any further PR action.

## Root worktree preservation

- Root is `main` at `65e36c13fac77163be695a750709495812400a7a`, six commits
  ahead of `origin/main`; do not commit/push unless explicitly requested.
- Intended dirty task files include subtitle bootstrap/setup/tests, Japanese
  updater/tests/settings/docs/reference CSV, fontconfig, and Ghostty. README
  contains shared subtitle/Japanese/Appgate changes.
- Preserve unrelated `.zshrc` cursor/Mise work and Firefox keybinding patch.
- Preserve the user's edits to
  `japanese/anime/subtitles/monogatari/bakemonogatari/subs.en/Bakemonogatari 03 - Mayoi Snail, Part 1.en.ass`;
  they change three English translations and are not part of the PR work.
- Firefox Alt+A still needs a Vimium-disabled test before changing Kanata/XKB.
