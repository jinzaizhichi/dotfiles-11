# Handoff

## Continuation guidance

Treat repository state as authoritative if it conflicts with this file. Inspect
status/diffs before editing, preserve unrelated changes, and do not repeat
completed investigation or reconstruct project history unless current state
contradicts this handoff. Do not commit or push any repository without explicit
instruction. For mpvacious commits use `kuator <kuator578@gmail.com>` explicitly;
the global Git identity was previously wrong.

## Current objective

The root dotfiles bootstrap work described below is complete and was requested
to be committed and pushed. Remaining work is manual verification: back up the
Atuin encryption key in Bitwarden, test CodeCompanion command completion in a
new Neovim process, finish live verification of mpvacious PRs #180 and #177,
and perform the pending Ghostty and Japanese Sentences visual checks.

## CodeCompanion/Codex ACP: implemented, uncommitted

- Root `scripts/optional/shell/install-codex.sh` now installs both
  `@openai/codex@latest` and `@agentclientprotocol/codex-acp@latest` through the
  Mise-managed npm, then reshims. README and bootstrap assertions were updated.
- `codex-acp` 1.2.0 is installed on PATH through Node 20.20.2.
- `/home/evakuator/.config/nvim` manages Plenary and CodeCompanion with
  `vim.pack`, deferring them until a `CodeCompanion*` command is entered.
  CodeCompanion is locked at `9a8e8602a7c72d10a827880fbb6fcd8bfa3830c7`.
- The built-in `codex` ACP adapter uses `auth_method = "chat-gpt"`. Model and
  reasoning level are deliberately not hard-coded so Codex remains authoritative.
- Mappings: `<leader>aa` actions, `<leader>ac` toggle chat, visual `<leader>as`
  add selection.
- `CmdUndefined` permits an unknown command to execute but cannot expose it to
  command completion. Therefore the shared `config.lazy.commands()` helper also
  watches `CmdlineChanged` and loads a matching plugin after
  `min(3, command-prefix length)` characters. This intentionally fixes every
  caller (Mason, Telescope, DAP, Treesitter, CodeCompanion, etc.) while retaining
  lazy startup. A process that cached the old module/autocmds must be fully
  restarted before testing.

Verification already passed:

- `codex-acp --version` -> `@agentclientprotocol/codex-acp 1.2.0`.
- Headless CodeCompanion setup/load through `config.lazy`.
- Fresh-process simulated `:CodeComp` entry loaded CodeCompanion and exposed
  `CodeCompanionChat` through `getcompletion()`.
- An equivalent temporary fresh-process `:Mas` test loaded Mason and exposed
  `Mason`; the temporary test was removed afterward.
- From `/home/evakuator/.config/nvim`:
  - `nvim --headless -c 'luafile tests/lazy_command_completion.lua'`
  - `nvim --headless -c 'luafile tests/lazy_commands.lua'`
  - `nvim --headless -c 'luafile tests/lazy_loading.lua'`
- `shfmt -d scripts/optional/shell/install-codex.sh` and `git diff --check` in
  both repositories.

Known unrelated/non-regression failure:

- `nvim --headless -l tests/lazy_commands.lua` reported `Telescope was not
  restored`; the supported normal-startup form using `-c 'luafile ...'` passes.

Manual `:Mas<Tab>`/`:CodeComp<Tab>` verification after a full restart is still
pending. Cached loader state is the leading explanation for the user's earlier
interactive Mason failure, not a confirmed cause.

Relevant files:

- Root: `scripts/optional/shell/install-codex.sh`, `tests/bootstrap.sh`,
  `README.md`.
- Neovim: `lua/config/lazy.lua`, `lua/config/codecompanion.lua`,
  `plugin/codecompanion_nvim.lua`, `tests/lazy_command_completion.lua`,
  `tests/lazy_loading.lua`, `nvim-pack-lock.json`.

## Completed desktop, security, and bootstrap work

- The official Bitwarden desktop package is installed reproducibly from a
  pinned release and checksum. Account creation, 2FA, and recovery material stay
  manual.
- Atuin 18.19.0 is installed through Mise, imported 14,189 Zsh history entries,
  and completed its first encrypted sync as `kuator578`. Its Zsh integration
  leaves fzf `Ctrl+R` and arrow bindings alone. Atuin's secret filter and a
  conservative `zshaddhistory` hook reject obvious password/token/API-key
  commands; `HIST_IGNORE_SPACE` remains an extra fallback. Back up `atuin key`
  in Bitwarden, never in Git.
- The XM6 audio guard mutes fallback outputs after headphone disconnects and
  unmutes only the headphones on reconnect. `bin/fix-xm6-audio` repairs stale
  Bluetooth transports and restores the XM6 as the default sink.
- Cinnamon installs KDocker plus a small X11 close-to-tray helper for Appgate;
  KDE installs pinned KWin Minimize2Tray. Appgate's title-bar close hides its
  window, while the tray-menu close actually quits it.
- The Japanese setup installs the pinned `kuator/yomichan-forvo-server` fork,
  preserves its configuration, and caps slow lookups. Yomitan disables default
  audio sources and uses a five-second Anki media download timeout.
- Mise now also installs Neovide and presse. The bootstrap installs the Codex
  ACP adapter alongside Codex.

Relevant files: `scripts/bootstrap/install-bitwarden.sh`,
`configs/xdg/atuin/`, `configs/xdg/zsh/.zshrc`,
`configs/xdg/xm6-audio-guard/`, `bin/fix-xm6-audio`, `bin/appgate`,
`scripts/bootstrap/install-window-tray.sh`, and
`scripts/optional/japanese/install-yomitan-forvo-server.sh`.

## mpvacious PR #180: review addressed and pushed; live check pending

- The original bug allowed a single recent/selected/automatic note update to
  overwrite unrelated sentence/media fields. The guard is at the shared
  `note_exporter.update_notes` boundary, covering all update paths.
- Stored `SentKanji` and the current primary subtitle are compared after HTML,
  whitespace, supported quote/entity, and case normalization. Either may contain
  the other, preserving highlighted or expanded-sentence updates. Empty current
  subtitles remain allowed for manually transcribed/image-subtitle cards.
- A mismatch uses a centered high-priority confirmation, safe default `No`,
  Left/Right navigation, Enter, explicit `y`/`n`, and a 10-second timeout.
  Cancellation now clears subtitle/quick-creation update state and refreshes the
  menu (`30e6ea6b8fffd3781a912e5dad4a06365e403866`) so stale selections do not
  remain after declining an update.
- Regression shape: stored `そのメモ ちょっと<b>貸して</b>みろよ` versus
  current `無視された 小学生女子に シカトされた`.
- PR #180 is OPEN, non-draft, head
  `988311a` on
  `kuator:fix/confirm-mismatched-recent-notes`. GitHub's API reported
  `mergeable_state: dirty` on 2026-08-13; recheck before acting.
- Ren's feedback is addressed in `988311a`: confirmation now uses
  `mp.input.select`, keeps `No` as the safe default, preserves the 10-second
  timeout/cancellation cleanup/no-media-before-confirmation behavior, and splits
  the long tests into focused helpers and cases.
- Multi-note and current-subtitle mismatch reasons are collected before opening
  the selector, so one update now produces one combined confirmation instead of
  two sequential prompts.
- `luajit tests/run.lua`, Lua bytecode loading, and `git diff --check` pass on
  both the PR-only branch and the combined local branch. Live mpv interaction is
  still pending; no mpv process was running after the final checks.

Relevant file: `configs/xdg/mpv/scripts/mpvacious/mpvacious/anki/note_exporter.lua`.

## mpvacious PR #177: implemented draft; required live regression pending

- Forward `sub-step 1 secondary` discovery is retained. Full-track/ffmpeg
  extraction was rejected because it is slower/more complex and embedded-track
  lookahead is naturally constrained by mpv's prefetch range.
- Secondary overlap requires 75% when the shorter interval is under one second
  and 50% otherwise. A cue may pass against the combined primary window or a
  clipped individual primary cue.
- Automated suites and real-mpv probes previously passed for external and
  embedded tracks, including delay restoration. Bakemonogatari mining/OSD
  verification is incomplete; keep the PR draft until it passes.
- PR #177 is OPEN/DRAFT/CLEAN at
  `81ca8809fefe2a5249861ffcef597a641c8bee0d` on
  `kuator:feat/full-track-secondary-overlap` (API checked 2026-08-13).
- Latest maintainer feedback: backward `sub-step` can be supported with a
  direction parameter if actual user need is established; consider splitting
  the PR into smaller PRs; explicitly comment when it is ready. These are not
  implemented requirements yet. Earlier user testing favored retaining forward
  discovery only, since normal rewind lets mpvacious cache prior cues.

Relevant modules: `mpvacious/subtitles/observer.lua`,
`mpvacious/subtitles/sub_list.lua`, `mpvacious/subtitles/subtitle.lua`,
`mpvacious/main.lua`.

## Completed Anki repair and maintained Japanese state

- A read-only audit found 3 of 424 `Japanese sentences` notes missing bold
  markup. Notes `1786373831833` and `1786373936153` were repaired.
- Hybrid note `1786472440491` was restored as the intended `貸す` card at EP03
  `18m44s686ms`; sentence media was cleared and `needs-media` added. New note
  `1786516492059` was created for `シカト` using existing EP03 media at
  `18m56s969ms`. Writes used AnkiConnect, never direct SQLite mutation.
- Verified final live state then: 425 notes, `missingBold: 0`, `emptyBold: 0`.
- Japanese Sentences retains upstream fields/cards plus `VocabFreq` after
  `VocabPitchNum`; updater pin
  `acc6d71d7fb0e9fc7f8cf286b813a128ad3d0c84`. Both Yomitan formats map
  `VocabDef` to `{glossary}` and `VocabFreq` to `{frequencies}`. Backfill is 337
  exact matches and 9 deliberate unmatched values; do not recreate the deleted
  one-off tool.
- `./tests/update-japanese-sentences.sh`, shell syntax, Yomitan JSON assertions,
  and relevant `git diff --check` passed. New mining was manually confirmed to
  store `VocabFreq`; Anki editor font was confirmed. Desktop/mobile card layout
  and frequency-chip comfort remain to be checked.
- Personal context outside Git: `/home/evakuator/zk/japanese/anki_deck_reset_urge.md`
  was created to address perfectionism/OCD-driven urges to delete and restart
  the Anki deck; preserve it.

Relevant files: `scripts/optional/japanese/update-japanese-sentences.sh`,
`tests/update-japanese-sentences.sh`, `japanese/yomitan/settings.json`.

## Other completed root work with pending manual checks

- Ghostty uses `UbuntuMono Nerd Font` then `Noto Sans Mono CJK JP`; fontconfig
  keeps strong Japanese/Arial fallbacks so Anki does not regress to Takao.
  Automated face selection and `ghostty +validate-config` passed. Visual restart
  check remains pending. Preserve font size 11, nonblinking block cursor,
  shell-integration cursor suppression, and `Ctrl+[`.
- `scripts/bootstrap/install-subtitle-sync.sh`, called by `scripts/setup.sh`,
  reproducibly installs ffsubsync 0.4.31, alass-cli 2.0.0, and autosubsync-mpv
  `a6dc1bbf86d82d001b34c6b223d1f82ee3d7b2cc`. Initial/idempotent installs,
  pins, post-install checks, shell syntax, Ubuntu 24.04 Cinnamon/Kubuntu 26.04
  simulations, Lua loading, and real versions passed. Ignore the unrelated
  missing-ruff environment warning from `uv tool list`.
- Firefox Alt+A still needs a Vimium-disabled test before changing Kanata/XKB.

## Repository/worktree state to preserve

- Root dotfiles: `main`, tracking `origin/main`. Inspect Git for the current
  commit rather than relying on a hash recorded here; the accumulated bootstrap
  work was requested to be committed and pushed on 2026-08-18.
- Neovim: `/home/evakuator/.config/nvim`, `main` at
  `965b62baaa5432dd764b810ab9acc32da5816091`, tracking `origin/main`. Preserve
  unrelated pre-existing changes in `lua/config/lsp.lua` and `plugin/lsp.lua`.
  CodeCompanion task changes are `lua/config/lazy.lua`,
  `lua/config/codecompanion.lua`, `plugin/codecompanion_nvim.lua`,
  `tests/lazy_command_completion.lua`, `tests/lazy_loading.lua`, and
  `nvim-pack-lock.json`.
- Nested mpvacious checkout is clean on local combined `master` at
  `77974a5`, 11 commits ahead of local
  `origin/master` (`98a29fa4fdab893c4050652c276b498ebf1f10d7`). It combines PR #177
  plus local equivalents of PR #180; do not push combined `master`. Local
  `pr-177` is `81ca880`; local `pr-180` is the actual pushed head `988311a`.

The earlier subtitle/Japanese/fontconfig/Ghostty, `.zshrc`, Firefox, and edited
Bakemonogatari English subtitle changes are now part of root commit `1eff2e2`,
not unrelated working-tree dirt. Preserve their behavior when touching those
areas.

## Exact next steps

1. Fully restart Neovim and manually verify `:Mas<Tab>` and `:CodeComp<Tab>`.
   If either fails in a new process, inspect `:verbose autocmd CmdlineChanged`,
   `:messages`, and `getcompletion('Mas', 'command')` before redesigning the
   loader. Then review both repository diffs; commit separately only if asked.
2. Recheck PR #180 state/review, then launch mpv and test a single unrelated note
   plus the multi-note path: `No` selected by default, Up/Down and Enter,
   10-second timeout, cancellation clearing update state, no media creation before
   confirmation, and one combined prompt when both mismatch checks fail.
3. Complete PR #177 Bakemonogatari regression mining. Positive primary cues
   `20:45.702–20:48.205` and `20:48.789–20:52.125` must export both Coalgirls
   sentences in order. English cue `20:43.200–20:47.740` overlaps 44.9% of the
   combined window but 81.4% of the first cue. Negative `うん 好きかな`
   (`12:41.594–12:43.179`) and `くっ` (`12:56.358–12:57.193`) must omit
   incidental English. Check OSD numbering/wrapping; horizontal wrapping exists,
   vertical scrolling does not. Then decide PR splitting/backward-scan feedback
   and comment only when ready.
4. Restart Ghostty and visually confirm `Aa0`, Nerd glyph U+E725, and `日本語`.
   If wrong, run `ghostty +show-face --string='Aa0 日本語 '` while preserving
   the working Anki Arial fallback.
5. Preview Japanese Sentences Recognition/Production answers on desktop/mobile.
   Review subtitle-sync only if new changes are proposed; its implementation and
   targeted verification are already complete.
