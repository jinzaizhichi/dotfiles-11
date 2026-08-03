# Dotfiles

Personal fresh-machine bootstrap for exactly two targets:

- Ubuntu 24.04 with Cinnamon
- Kubuntu 26.04 installed from its ISO with KDE Plasma

The steps below rebuild either machine; commands are run from the repository root unless stated otherwise.

## Fresh-machine runbook

### 1. Clone and bootstrap

```sh
sudo apt-get install -y git
git clone https://github.com/kuator/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
./scripts/setup.sh
```

This is the only automatic entry point. It rejects other Ubuntu release/desktop combinations before making changes, asks for sudo normally, installs the base APT packages and Zinit, links the tracked configuration, installs Mise-managed tools including Kanata and Bob's Neovim nightly, and applies the tracked desktop keyboard settings. It is safe to rerun: an existing destination is moved to `<name>-old`, and setup stops rather than overwriting an existing backup.

Run every remaining command only after `scripts/setup.sh` succeeds.

### 2. Configure the operating system and login

Disable Snap before installing Firefox, then apply the remaining system and shell changes:

```sh
./scripts/optional/system/disable-snap.sh
./scripts/optional/shell/configure-bash-xdg.sh
./scripts/optional/shell/set-default-zsh.sh
./scripts/optional/system/configure-kanata.sh
./scripts/optional/system/configure-ssh-xdg.sh
./scripts/optional/system/disable-sudo-admin-flag.sh
```

The final script applies the legacy home-marker fix on Ubuntu 24.04 and exits without changing anything under Kubuntu 26.04's sudo-rs.

Close every Codex process, then install Codex with its home under `$XDG_DATA_HOME`. The script also migrates an existing `~/.codex`:

```sh
./scripts/optional/shell/install-codex.sh
```

Install the Appgate Debian package before installing the XDG wrapper. For example, from the directory containing the package:

```sh
sudo dpkg -i AppGate-SDP-client.deb
cd "$HOME/dotfiles"
./scripts/optional/system/configure-appgate-xdg.sh
```

The Appgate wrapper uses a private fake home under `$XDG_DATA_HOME`; the system service and running VPN client remain vendor software.

### 3. Log out or reboot

Reboot before continuing. This activates the new login shell, Kanata group membership, system keyboard configuration, and any display-manager changes.

After logging in, `configs/system/keyboard` is the source of truth for layouts and switching. Cinnamon applies it through X11 and KDE derives its keyboard configuration from the same file.

### 4. Configure desktop applications

Install the shared terminal font:

```sh
./scripts/optional/desktop/install-ubuntu-mono-nerd-font.sh
```

#### Ubuntu 24.04 Cinnamon

Import the GNOME Terminal profile, then apply the LightDM home-cleanup changes used by this machine:

```sh
./scripts/optional/desktop/import-gnome-terminal-profile.sh
./scripts/optional/desktop/lightdm/configure-xauthority.sh
./scripts/optional/desktop/lightdm/patch-binary.sh
```

#### Kubuntu 26.04 KDE

Use Kubuntu's installed KDE terminal and display manager. Do not run the GNOME Terminal or LightDM scripts; the bootstrap has already written KDE's keyboard and repeat settings.

#### Shared applications

Install Firefox after Snap has been disabled:

```sh
./scripts/optional/firefox/install.sh
```

Launch Firefox once so it creates a default profile, then close Firefox and run:

```sh
./scripts/optional/firefox/configure-profile.sh
./scripts/optional/firefox/patch-keybindings.sh
./scripts/optional/firefox/configure-new-tab.sh
```

Install New Tab Override and Vimium through Firefox Add-ons. In New Tab Override, select **Custom URL**, enter `http://127.0.0.1:8766/blank.html`, and enable focusing the website instead of the address bar. In Vimium, set **New tab URL** to **Browser's default new tab page**. Firefox requires these extension changes to be made manually.

The new-tab service binds only to `127.0.0.1`. Firefox updates replace `omni.ja`, so rerun `firefox/patch-keybindings.sh` after an update if the custom browser shortcuts stop working.

### 5. Restore Japanese study tools

Install Anki, link mpv configuration, install mpvacious, and check the Anki add-on manifest:

```sh
./scripts/optional/japanese/setup.sh
```

Paste any printed codes into **Anki → Tools → Add-ons → Get Add-ons**, then restart Anki. After add-on `1045800357` exists, restore its optional 2.5 GiB local-audio collection:

```sh
./scripts/optional/japanese/download-yomitan-audio.sh
```

The torrent and archive stay in `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/yomitan-audio`; the main bootstrap never starts this download.

The eight selected Yomitan dictionary ZIPs are carried directly in `japanese/yomitan/dictionaries/`. If an archive is missing, restore it from the manifest:

```sh
./scripts/optional/japanese/download-yomitan-dictionaries.sh
```

In Yomitan, import the numbered archives from `japanese/yomitan/dictionaries/`, then import `japanese/yomitan/settings.json` from **Settings → Backup → Import Settings**. Follow `japanese/yomitan/README.md` to apply the tracked order to the currently selected profile.

Finally, start Anki with AnkiConnect enabled and update or create the official Japanese Sentences note type with the local compatibility changes:

```sh
./scripts/optional/japanese/update-japanese-sentences.sh
```

Restart Anki afterward so AJT Japanese refreshes its injected CSS and JavaScript.

### 6. Verify the machine

```sh
./tests/bootstrap.sh
nvim --version
mise doctor
test ! -e "$HOME/.appgate" && echo 'Appgate home is clean'
```

On Ubuntu 24.04 Cinnamon/X11, also run `setxkbmap -query`. On Kubuntu 26.04, run `kreadconfig6 --file kxkbrc --group Layout --key LayoutList`. The first command above is the repository regression suite; the others are quick checks of installed tools and machine-level changes.

## Repository map

### Configurations and study resources

- `configs/home/profile` defines the login environment, XDG locations, and user-tool paths and is linked to `~/.profile`.
- `configs/xdg/` contains application configuration linked into `$XDG_CONFIG_HOME`, grouped by application. Notable exceptions handled specially by the linker are Codium's files and the global `ty.toml`.
- `configs/system/keyboard` is the single tracked source for the system, Cinnamon, KDE, IBus, and live X11 keyboard layout; `configs/gnome-terminal/profile.dconf` is imported rather than linked.
- `docs/ergonomic-keyboard.md` records the ergonomic-keyboard requirements, shortlist, and current recommendation.
- `japanese/anki/addons.txt` is the named AnkiWeb add-on manifest.
- `japanese/yomitan/dictionaries.txt`, `japanese/yomitan/settings.json`, and `japanese/yomitan/sort-dictionaries.js` define the selected dictionaries, exported settings, and active-profile order.
- `japanese/anime/` contains older subtitle timing tools and source-specific data; it is not part of bootstrap.

### Automatic bootstrap

- `scripts/setup.sh` is the only entry point.
- `scripts/bootstrap/install-packages.sh` installs Ubuntu packages.
- `scripts/bootstrap/link-configs.sh` backs up and links tracked configuration.
- `scripts/bootstrap/install-mise.sh` installs Mise-managed CLI tools and Bob's Neovim nightly.
- `scripts/bootstrap/configure-desktop.sh` derives desktop keyboard settings from `configs/system/keyboard`.

### Manual setup

Nothing under `scripts/optional/` runs automatically. Several scripts use sudo, alter installed software, or require an application to be open or closed.

| Script | Purpose |
| --- | --- |
| `desktop/import-gnome-terminal-profile.sh` | Imports the tracked GNOME Terminal profile. |
| `desktop/install-ubuntu-mono-nerd-font.sh` | Downloads and installs UbuntuMono Nerd Font. |
| `desktop/lightdm/configure-xauthority.sh` | Stores LightDM Xauthority data outside the home root. |
| `desktop/lightdm/patch-binary.sh` | Patches LightDM to move `.xsession-errors`; use only with LightDM. |
| `firefox/configure-new-tab.sh` | Enables the localhost-only tracked new-tab page service. |
| `firefox/configure-profile.sh` | Links Firefox preferences and content CSS into its default profile. |
| `firefox/install.sh` | Installs Firefox from the Mozilla Team PPA. |
| `firefox/patch-keybindings.sh` | Rebuilds Firefox's `omni.ja` with the custom shortcuts. |
| `japanese/download-yomitan-audio.sh` | Downloads, caches, and installs the optional local-audio collection. |
| `japanese/download-yomitan-dictionaries.sh` | Restores missing dictionary archives from the tracked manifest. |
| `japanese/setup.sh` | Installs Anki and mpvacious and reports missing Anki add-ons. |
| `japanese/update-japanese-sentences.sh` | Fetches upstream Japanese Sentences, applies compatibility patches, and updates it through AnkiConnect. |
| `shell/configure-bash-xdg.sh` | Makes system Bash startup and history use XDG locations. |
| `shell/install-codex.sh` | Installs Codex through Mise-managed npm with an XDG data home and migrates an existing `~/.codex`; Codex must be closed. |
| `shell/set-default-zsh.sh` | Interactively changes the login shell to Zsh. |
| `system/configure-appgate-xdg.sh` | Installs the Appgate fake-home wrapper with `dpkg-divert`. |
| `system/configure-kanata.sh` | Configures Linux groups, udev, and uinput, then enables the tracked Kanata user service. |
| `system/configure-ssh-xdg.sh` | Makes all OpenSSH clients use the tracked XDG config and migrates host keys. |
| `system/disable-snap.sh` | Removes Snap while preserving user data and prevents its reinstallation. |
| `system/disable-sudo-admin-flag.sh` | Prevents classic sudo from creating its home marker; safely does nothing under sudo-rs. |

### Wrapper

- `bin/appgate` gives the vendor Appgate client a private fake home.
- `bin/codium` launches VSCodium with its XDG data directory.
- `bin/fd` exposes Ubuntu's `fdfind` executable under its upstream `fd` name.
- `bin/rg` makes ripgrep share the ignore file used by fd.

### Test

- `tests/bootstrap.sh` checks links, environment settings, desktop configuration, wrappers, migrations, and documented scripts.
- `tests/python-environment.sh` checks the `venv`-based uv and ty project environment.
- `tests/update-japanese-sentences.sh` exercises note-type download, patching, and AnkiConnect behavior with local fakes.
- `tests/yomitan-sort-dictionaries.js` checks dictionary ordering without Yomitan.

### Downloaded/vendor content

- `japanese/anki/addons21/` contains downloaded Anki add-ons and is intentionally ignored; `japanese/anki/addons.txt` is the reproducible source list.
- `japanese/yomitan/dictionaries/` contains the eight Git-tracked importable archives. Their internals are third-party data and are not documented here.
- `configs/xdg/mpv/scripts/mpvacious/` is the installed upstream mpvacious checkout. `japanese/setup.sh` installs the pinned release and reapplies the intentional menu-line-length mutation.

## Maintenance rule

Put general declarative configuration under `configs/` and Japanese study resources under `japanese/`. Put automatic fresh-machine work under `scripts/bootstrap/` and call it from `scripts/setup.sh`; put destructive, optional, application-dependent, or machine-level work under the matching `scripts/optional/` responsibility folder. Add a regression check when behavior—not just data—changes.
