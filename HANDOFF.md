# Repository handoff

This file preserves the context that is not obvious from the files alone. It is
for continuing work on this repository after a long conversation or in a new
session. The operational fresh-machine instructions remain in `README.md`.

## Working conventions

- Primary branch: `main`
- Git identity: `kuator <kuator578@gmail.com>`
- Do not commit or push merely because work is complete; wait until explicitly
  requested.
- Preserve unrelated dirty changes. The user has explicitly rejected creating a
  separate worktree just to handle an already-dirty repository.

## User priorities

These preferences have driven most repository decisions:

- Minimize cognitive load while retaining a clean separation by responsibility.
- Prefer descriptive directory and script names over clever or generic names.
- Prefer native platform features, existing tools, and short scripts over new
  dependencies or abstractions.
- Keep `$HOME` clean. Prefer supported XDG variables and native paths; use a
  narrowly scoped fake home only for applications that cannot be configured.
- Do not use symlinks solely to hide non-XDG application clutter.
- Do not mutate system files when a user-level solution is sufficient.
- Optional, expensive, destructive, or machine-specific operations must never
  run silently from the main bootstrap.
- A fresh machine is the main use case. Scripts should be safe to rerun and must
  report missing prerequisites clearly.
- Fetch current upstream data or templates when freshness matters; do not silently
  preserve an obsolete vendored copy.
- Avoid speculative cleanup of study data. Preserve subtitle timing and semantic
  content unless a transformation has been explicitly requested.
- The project named Graphify was removed completely. Do not mention, restore, or
  account for it.

## Supported systems

The intended targets are:

1. The current Ubuntu 24.04 Cinnamon/X11 installation.
2. A future Kubuntu 26.04 installation made directly from its ISO.

Kubuntu 24.04 and an in-place Ubuntu-to-KDE conversion are not targets. Desktop
configuration should detect `XDG_CURRENT_DESKTOP` and handle Cinnamon or KDE
without installing either desktop environment.

Kanata's configuration is Linux-specific as checked in. The behavior can be
recreated on Windows or macOS, but the device names, key names, permissions, and
service setup are not portable as-is.

## Repository architecture

### Entry point

`scripts/setup.sh` is the only automatic entry point. It runs the bootstrap
stages in `scripts/bootstrap/`:

- `install-packages.sh` installs the distro-owned base packages.
- `link-configs.sh` installs declarative files into their destination paths.
- `install-mise.sh` installs user-level development tools.
- `configure-desktop.sh` applies the supported desktop's settings.

Anything in `scripts/optional/` is manual. The main bootstrap must not invoke it.
Optional scripts are grouped by responsibility:

- `desktop/`: terminal profile, font, and Steam.
- `firefox/`: Firefox installation and profile-dependent configuration.
- `japanese/`: Anki, mpvacious, dictionaries, audio, and note attribution.
- `shell/`: shell/Codex setup that is not universal bootstrap work.
- `system/`: privileged or policy-changing integration such as Kanata, SSH,
  Appgate, Snap, and sudo behavior.

### Data and configuration

- `configs/` contains declarative machine configuration.
- `configs/xdg/` mirrors destinations below `XDG_CONFIG_HOME`.
- `configs/home/profile` is the tracked login environment.
- `configs/system/keyboard` is the tracked keyboard-layout source of truth.
- `configs/gnome-terminal/profile.dconf` is application data imported explicitly,
  not an XDG symlink target.
- `japanese/` contains study resources and reproducible study setup. It is not a
  generic application-configuration directory.
- `bin/` contains small wrappers needed to make installed applications obey the
  repository's conventions.
- `tests/` contains shell and small integration checks. `tests/bootstrap.sh` is
  an idempotence/regression check, not a prerequisite for running the bootstrap.
- `docs/` contains durable auxiliary notes such as the ergonomic-keyboard
  shortlist and outstanding TODOs.

The root `README.md` is the fresh-machine runbook and concise repository map. Do
not turn it into an exhaustive inventory; put non-obvious continuation context
here.

## Tool ownership and shell environment

The ownership boundary is deliberate:

- Apt owns Ubuntu base utilities and system integration.
- Zinit owns Zsh plugins only, not general command-line programs.
- Mise owns user-level CLI tools, including Rust itself, uv, Bob, lazygit,
  lazydocker, shfmt, k9s, and zk.
- Bob owns the active Neovim nightly. The Ubuntu Neovim package and old Neovim
  AppImage were removed.
- Mason owns editor-only tools such as Stylua.
- uv owns Python project environments; Ubuntu still owns `/usr/bin/python3`.

Rustup was removed in favor of Mise-managed Rust. uv is likewise installed by
Mise. `UV_PROJECT_ENVIRONMENT=venv` makes the project environment a visible
`venv/` directory rather than `.venv/`. The global ty configuration points at
`venv`. The old centralized `workon_home` was deleted; `workon` is now only a
small project convenience, not a separate environment manager.

The global Git ignore and search ignore include `venv`. fd and ripgrep are
wrapped so both respect the shared ignore policy without creating `~/.ignore`:

- `bin/fd` also adapts Ubuntu's `fdfind` command to the conventional `fd` name.
- `bin/rg` applies the repository's shared ignore configuration.

Modern CLI replacements are explicit rather than aliases that unexpectedly
change standard commands: bat, eza, delta, and bottom are installed for direct
use.

Zsh history lives under XDG state rather than the repository. The open TODO is to
choose an open-source password manager and then configure Atuin for encrypted,
synced history. uv and broader command completion improvements were postponed.

## Home-directory and XDG policy

Known special cases:

- Codex uses `CODEX_HOME=$XDG_DATA_HOME/codex` and is installed by
  `scripts/optional/shell/install-codex.sh`. Its launcher must resolve the current
  standalone release rather than one hard-coded release directory.
- NLTK uses `NLTK_DATA=$XDG_DATA_HOME/nltk`.
- SSH is configured through `~/.config/ssh/config`. A system OpenSSH include is
  installed so plain `ssh`, `scp`, `sftp`, rsync, and Git do not depend on shell
  aliases. Do not reintroduce redundant `ssh -F` or `scp -F` aliases.
- Java crash logs are directed to XDG state. Old `hs_err_pid*.log` files in home
  were leftovers, not evidence that the current redirect was absent.
- Steam uses the fixsteam-based fake-home approach through `bin/steam` and
  `scripts/optional/desktop/install-steam.sh`. The Steam AppImage approach was
  abandoned because it required disabling Ubuntu's AppArmor restriction on
  unprivileged user namespaces. Do not disable that security control.
- Appgate uses `bin/appgate` with a fake home below
  `$XDG_DATA_HOME/appgate/home`. `scripts/optional/system/configure-appgate-xdg.sh`
  installs the wrapper using `dpkg-divert`, so the system desktop entry and
  absolute `/usr/bin/appgate` launches also pass through it. The vendor binary is
  retained as `/usr/bin/appgate.vendor`.
- If .NET is installed later, prefer its supported environment variables. Do not
  add a fake home preemptively.

Past clutter audits removed caches, obsolete installers, retired applications,
old toolchains, unused game data, and stale configuration. Do not repeat that
cleanup from memory: inspect current ownership and usage before deleting anything.

## Desktop and keyboard

`configs/system/keyboard` is the single tracked source for keyboard layouts and
options. `configure-desktop.sh` applies it to the system, the detected Cinnamon or
KDE desktop, IBus where relevant, and the live X11 session. The intended layout
set is US and Russian with Alt+Shift switching. Do not restore a separate,
competing GSettings-only source of truth.

Kanata is optional and installed by
`scripts/optional/system/configure-kanata.sh`. That script installs and enables a
systemd user service; the repository does not currently support a non-systemd
service manager.

The intended Shift behavior is:

- Tap either Shift once: latch Shift for the next character.
- Hold Shift: ordinary held Shift.
- Double-tap Shift: hold Shift as a layer/state.
- Tap Shift once while held: release that state.

A Space-based convenience layer was added for easier modifier/symbol access, but
Space combinations for `[`, `/`, and `]` were explicitly rolled back because they
interfered with normal typing.

A minimal US-only XKB variant remains necessary. Kanata could not correctly
reproduce the desired grave/tilde inversion while also preserving Russian `ё`:

- US physical grave key produces `~`; Shift produces a backtick.
- Russian physical grave key produces lowercase `ё`; Shift produces uppercase
  `Ё`.

Earlier attempts to encode the custom layout as an RMLVO variant produced broken
names such as `tilde-first,ru-` and crashed QtWebEngine/Anki. Do not restore that
approach. The current minimal XKB integration was chosen to avoid cross-layout
corruption.

Kanata event timing was investigated after Shift occasionally failed in Teams and
Telegram. A global rapid-event delay made Vim movement and arrow keys feel laggy.
Key repeat is separately restored with `xset r rate 220 40` after Kanata reloads;
repeat rate does not replace event ordering. Re-test real layout-switch + latched
Shift behavior before changing timing again.

The user may eventually buy an ergonomic split keyboard to move modifiers and
symbols to thumb clusters. The current shortlist and requirements are in
`docs/ergonomic-keyboard.md`.

## Neovim

The user prefers the latest Neovim nightly, installed by Bob through Mise. Startup
was reduced from roughly 354 ms to roughly 204 ms and then refined further using
native targeted loading rather than adding another plugin manager.

The loading architecture uses straightforward Neovim primitives:

- commands and key mappings load command-oriented plugins on demand;
- `InsertEnter`/`CmdlineEnter` load insert and command-line helpers;
- `FileType` loads language- or buffer-specific plugins;
- `LspAttach` loads LSP presentation helpers;
- universally useful UI, options, mappings, and a few cheap plugins stay eager.

Debugprint was deliberately restored to eager initialization. The approximately
4 ms cost was accepted because its mapping-triggered loader was the least readable
part of the lazy-loading design. vim-startify remains despite being Vimscript
because the user likes it.

Plugins explicitly retained despite little command-history evidence include
nvim-dap, neotest, and lazy-loaded refactoring.nvim; the user considers them useful
and intends to learn them. Also retain:

- nvim-early-retirement;
- netrw.nvim and Vinegar for the enhanced/icon workflow, alongside Oil;
- treesj and vim-illuminate;
- dsf.vim, substitute.nvim, Tabular, treesitter-unit;
- vim-textobj-variable-segment, vim-textobj-entire, and vim-textobj-line.

Plugins intentionally removed as unused or redundant included git-time-lapse,
yaml.nvim, vim-obsession, comment-box, aerial, git-blame, marks, undotree, opsort,
vim-exchange, vim-lion, vim-sort-motion, vim-textobj-xmlattr, and text-case. Do not
restore them based solely on their theoretical usefulness.

vim-rsi was adjusted to work in the `q:` command-line window. LuaSnip provides
operator conveniences including `ar` -> `->`, `dc` -> `::`, and `fa` -> `=>`, and
the relevant snippets were made available in `.env` files. An autopairs plugin was
tried and removed because the user disliked it.

## Firefox

Firefox configuration lives under `configs/xdg/firefox`; Firefox scripts remain
in `scripts/optional/firefox` because applying the configuration is procedural.

Firefox must have been launched once so a profile exists before profile-dependent
scripts run. Those scripts should fail with a clear prerequisite message; they
must not silently launch Firefox. There is therefore an intentional manual order:

1. Install Firefox.
2. Launch it once and close it.
3. Configure the profile, new-tab behavior, and keybindings.

The local new-tab page is served locally to avoid extension-page limitations and
uses a dark fallback to prevent a nauseating white flash while the background
loads. Vimium and New Tab Override were configured around this arrangement.

Firefox keybindings require the `omni.ja` patch. Alt+A and Alt+S were restored;
Alt+D required particular care. Do not automatically delete Firefox's startup
cache from the patch script without proving it is necessary, because cache
ownership and running-profile state make that unsafe.

## Japanese study system

Japanese resources live under `japanese/`, with application/setup scripts under
`scripts/optional/japanese/`.

### Anki

- Primary deck: `MyJapanese`; old `MyMining` references should not return.
- The same Japanese Sentences note type is used for anime and book mining.
- `japanese/anki/addons.txt` is the declarative add-on list. Downloaded add-on
  payloads are ignored; the Git-only Japanese add-on remains separate where its
  install method requires it.
- The optional local-audio downloader uses aria2, caches the roughly 2.5 GiB
  archive below `$XDG_CACHE_HOME/dotfiles/yomitan-audio`, and extracts it into the
  add-on's `user_files`. The main bootstrap must neither require an archive in
  `~/Downloads` nor start this download unexpectedly.

`scripts/optional/japanese/update-japanese-sentences.sh` must fetch the latest
Ajatt-Tools Japanese Sentences template and apply only the local compatibility
changes. Do not replace it with an old local export. Local changes include the
field/edit compatibility needed by the current workflow, support for the upstream
hint-definition variant, and showing the card image by default on mobile. The user
previously caught an outdated template, so verify upstream freshness whenever this
script changes.

The current card workflow uses visible HTML audio controls rather than restoring
Anki `[sound:...]` markup. Snapshot output is WebP at quality 92, chosen to improve
clarity without the storage cost of lossless images or quality 100.

An experimental CSS change that moved Jitendex list markers inside the glossary
box was fully rolled back. The user accepts the small marker spillover and prefers
the upstream rendering to the broken padding/indentation result.

### Yomitan

Yomitan belongs under `japanese/yomitan`, not under Firefox or generic configs.
The canonical export is `japanese/yomitan/settings.json`. After changing live
settings, export and replace that canonical file deliberately.

The carried dictionary order is:

1. Jitendex
2. 新和英
3. 旺文社国語辞典 第十一版, no-images edition
4. Dictionary of Japanese Grammar
5. JPDB frequency
6. CC100 frequency
7. KANJIDIC English, with its release date included in the archive name
8. NHK 2016 pitch accent

小学館例解学習国語 第十二版 was replaced by 旺文社 because the former caused
noticeable lookup lag. Jitendex can also add cost, but is retained because it is
the main comprehensive learner dictionary. Dictionary archives are carried in
the repository; downloader metadata/scripts remain useful for refreshing them.

`japanese/yomitan/sort-dictionaries.js` is pasted into the Yomitan options-page
developer console and operates on the currently selected profile. Keep it aligned
with the canonical dictionary names.

The Yomitan Anki field template uses an HTML `<audio controls>` element for audio.
The `Notes` field uses `{document-title}` so direct lookups in ttu Reader record the
book title automatically. A lookup copied into Yomitan's standalone `search.html`
page records `Yomitan Search` instead, because the source document is lost.

`scripts/optional/japanese/attribute-epub-cards.py` repairs that attribution:

- It reads one EPUB with Python's standard library and queries AnkiConnect.
- It normalizes EPUB text and each note's `SentKanji`.
- Dry-run is the default and lists affected notes.
- `--apply` writes the EPUB title to `Notes` only when `Notes` is empty or exactly
  `Yomitan Search`; it never overwrites meaningful attribution.
- Any occurrence in the EPUB qualifies. Repeated sentences in the book and
  multiple Anki notes for the same sentence are supported.

The local Yomitan dictionary database is browser-extension storage. Anki media
cleanup and sync do not touch it.

### mpvacious and mpv

mpv configuration lives under `configs/xdg/mpv`. mpvacious is installed during
the optional Japanese setup rather than vendored permanently as an opaque copy.
Its configuration is still mutated where upstream does not expose the required
option. Treat its displayed update notice as authoritative rather than recording a
version here.

The active mpvacious profile is `subs2srs`, targeting the `MyJapanese` deck.
`card_overwrite_safeguard`, snapshot quality, template compatibility, and the
update notice have already been addressed.

The local fork is `/home/evakuator/dev/personal/mpvacious`. Its Git remote was the
user's fork, while upstream changes must be fetched from the original project.
Review the remotes before pulling or pushing. The deduplication/cue-overlap work
was applied both to the fork and the mpv copy used by the current installation.

The current subtitle-cue behavior is:

- External SRT and ASS tracks are parsed directly in Lua.
- Embedded tracks are extracted asynchronously through mpvacious's ffmpeg
  executable resolver.
- Card creation uses the prepared cache and does not synchronously parse an entire
  track.
- A Japanese cue can collect every overlapping English cue, joined with spaces;
  this covers one Japanese cue spanning three English cues.
- Deduplication normalizes only punctuation variants known to create real
  duplicate cards. Do not add speculative symbol equivalences.
- Do not mention Yomitan in upstream mpvacious contribution text; the maintainer
  asked that it not be referenced there.

The repository's anime subtitle directories use `subs.ja` and `subs.en`. Tracked
subtitles were conservatively cleaned by removing inactive ASS comments, duplicate
events after typesetting removal, explicit sign/song positioning or drawing
overrides, and tagged Sonny Boy song cues. Retained cue timing and boundaries were
not aggressively realigned. Some Default-style on-screen text remains because it
is structurally indistinguishable from dialogue after positioning tags are gone.

The user considered deleting low-learning-value cues such as `ハッ`, `あっ`, and
`ん`, then decided not to modify them.

`configs/xdg/mpv/mpv.conf` searches `subs.ja:subs.en`. Japanese should be primary
and English secondary. The local Bakemonogatari subtitle directory was also
renamed from `subs.jp` to `subs.ja` outside Git.

The machine's system mpv configuration forces VAAPI. Bakemonogatari's H.264 High
10 video is unsupported by the AMD VAAPI decoder, causing repeated
`decode_slice_header error`/`no frame` messages before fallback. Only the
Bakemonogatari profile therefore sets `hwdec=no`. Erased, Fullmetal Alchemist,
Sonny Boy, and Kokoro were checked and retain hardware decoding for their supported
formats. Do not copy `hwdec=no` into every show profile.

mpvacious probing `xsel` may print `Subprocess failed: init` before successfully
falling back to `xclip`; that message is harmless on this setup.

## Appgate lifecycle and privacy boundary

Appgate is job-mandated and closed-source. The user wants its privileged driver
absent when the VPN is not in use.

The intended idle state is no Appgate process, an inactive and disabled
`appgatedriver.service`, and no Appgate tunnel or routes. Launching the desktop
shortcut while the driver is disabled starts the UI and its unprivileged user
service, but did not start the privileged driver or create a tunnel when tested.
To use the VPN, the explicit procedure is:

```sh
sudo systemctl start appgatedriver.service
appgate

# After disconnecting and quitting Appgate:
sudo systemctl stop appgatedriver.service
```

Yes, this means manually starting and stopping the driver for each work session.
That explicit lifecycle was preferred over a wrapper that might request privilege
or stop the VPN unexpectedly. A package reinstall or upgrade may re-enable the
service; verify it afterward.

When investigating Appgate, do not kill or restart a live session without explicit
permission. Earlier work preserved running PIDs while changing the launcher.

## Verification commands

Run the checks relevant to a change:

```sh
bash tests/bootstrap.sh
bash tests/python-environment.sh
bash tests/subtitles.sh
bash tests/update-japanese-sentences.sh
node tests/yomitan-sort-dictionaries.js
python3 tests/attribute-epub-cards.py
```

The EPUB integration test opens a local fake AnkiConnect server and may need to run
outside a restricted sandbox. For documentation-only changes, `git diff --check`
is sufficient unless the documentation reveals a code inconsistency.

## Open work and deferred decisions

- Set up an open-source password manager, then configure Atuin for encrypted and
  synchronized shell history; tracked in `docs/todo.md`.
- Improve uv and other shell completions later if the missing completion remains
  annoying.
- Revisit subtitle Default-style sign removal only with a semantic/manual audit;
  there is no reliable blanket rule at present.
- Revisit Kanata timing only with a reproducible layout-switch + sticky-Shift
  failure. Global delay already caused unacceptable navigation latency.
- Non-systemd Kanata startup is out of scope until the user actually moves to a
  distribution such as Artix or Devuan.
- KDE theme switching and full KDE configuration capture were discussed but are
  not implemented. The future Kubuntu target assumes KDE already came from its
  ISO.

Start a new maintenance session by reading this file, `README.md`, `docs/todo.md`,
and `git status --short` before changing anything.
