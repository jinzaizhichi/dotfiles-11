# TODO

- [ ] Finish setting up Bitwarden. Its official desktop package is installed by
  the bootstrap; create the account, install the browser/phone clients, enable
  2FA, and store a paper copy of the recovery information offline.
- [ ] Store the output of `atuin key` in Bitwarden, never in this repository.
  Atuin is installed through Mise, integrated without replacing the existing
  `fzf` `Ctrl+R` or arrow-key bindings, and syncing the imported history.
- [ ] After migrating to Kubuntu 26.04, revisit automatic XM6 reconnection.
  Test KDE/BlueZ 5.85's behavior first, then configure BlueZ's native
  auto-connect scan if manual connection is still necessary.
- [ ] Set up the encrypted off-site backup described in
  [`backups-and-qol.md`](backups-and-qol.md): choose a destination, configure
  the documented inclusions and exclusions, enable automatic backups, save the
  recovery secret in Bitwarden and offline, and test a restore.
- [ ] Review the quality-of-life shortlist in
  [`backups-and-qol.md`](backups-and-qol.md). Prioritize KDE Connect; consider
  Syncthing, tealdeer, duf, and scrcpy only if their described use is relevant.
- [ ] Decide whether the small personal-file subset also needs an
  `age`-encrypted emergency copy on GitHub. If implemented, keep the identity
  out of Git, avoid plaintext temporary archives, and test the restore path.
