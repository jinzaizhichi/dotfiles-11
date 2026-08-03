# Ubuntu and Kubuntu Support Design

## Goal

Support exactly two fresh-machine targets:

- Ubuntu 24.04 with Cinnamon
- Kubuntu 26.04 installed from its ISO with KDE Plasma

Continue carrying the selected Yomitan dictionaries directly in the repository.

## Platform contract

`scripts/setup.sh` validates the operating system, release, and desktop before running package installation or any other mutation. It accepts only the two supported combinations and reports the detected values when rejecting another system.

Kubuntu is assumed to be installed already. The repository does not install, replace, or convert desktop environments.

## Shared bootstrap

Both targets continue through the same package installer, configuration linker, Mise installer, and desktop dispatcher. Replace the removed `libncursesw5-dev` package with `libncurses-dev`, which is available on both supported releases.

Desktop settings remain capability-specific:

- Cinnamon uses its existing GSettings and live X11 configuration.
- KDE uses its existing `kwriteconfig6` configuration.

The tracked `configs/system/keyboard` file remains the source of truth for both targets.

## Release-specific manual setup

`scripts/optional/system/disable-sudo-admin-flag.sh` detects the installed sudo implementation. On sudo-rs it exits successfully without writing an unsupported `admin_flag` setting because sudo-rs does not create the legacy home marker. On classic sudo it retains the Ubuntu 24.04 behavior.

The README separates desktop-specific instructions:

- GNOME Terminal profile and LightDM changes apply only to the Ubuntu 24.04 Cinnamon machine.
- Kubuntu uses its existing KDE terminal and display manager; those Cinnamon-specific scripts are skipped.
- Shared Firefox, shell, Appgate, Kanata, SSH, Japanese-study, and verification steps remain common.

## Dictionaries

Track all eight existing ZIP archives under `japanese/yomitan/dictionaries/` with ordinary Git. The current collection is about 63 MiB and its largest file is about 39 MiB, so Git LFS is unnecessary and no archive exceeds GitHub's per-file limit.

Keep `japanese/yomitan/dictionaries.txt` and `scripts/optional/japanese/download-yomitan-dictionaries.sh` as the reproducible manifest and restoration/update path.

## Testing

Extend `tests/bootstrap.sh` with isolated `/etc/os-release` and desktop fixtures that prove:

- Ubuntu 24.04 with Cinnamon is accepted.
- Ubuntu 26.04 Kubuntu with KDE is accepted.
- Unsupported releases or desktop combinations fail before bootstrap helpers run.
- The shared package list uses `libncurses-dev` and not `libncursesw5-dev`.
- The sudo compatibility script is a no-op under sudo-rs and preserves its classic-sudo behavior.
- All dictionary ZIPs named by the manifest exist in the repository and remain below the ordinary Git hosting limit.

Tests continue to replace privileged and external commands with local fakes and do not change the real system.
