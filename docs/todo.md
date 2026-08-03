# TODO

- [ ] Set up an open-source password manager with synchronization and account
  recovery. Prefer Bitwarden for the simplest cross-platform setup; use
  KeePassXC only with a separate, tested database-sync and backup strategy.
- [ ] Set up Atuin after the password manager:
  - Install it through Mise and initialize Zsh without replacing the existing
    `fzf` `Ctrl+R` or arrow-key bindings.
  - Import `$XDG_STATE_HOME/zsh/history`, register for encrypted sync, and run
    the first sync.
  - Store the output of `atuin key` in the password manager, never in this
    repository.
  - Add the reproducible installation and shell integration to the bootstrap.
