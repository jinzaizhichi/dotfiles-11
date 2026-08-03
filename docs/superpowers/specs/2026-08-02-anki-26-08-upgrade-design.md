# Anki 26.08 Upgrade Design

Update the Japanese-study bootstrap from Anki's retired 25.09 launcher archive to the official 26.08 Linux x86_64 archive. Keep the existing version marker and upgrade flow, but extract `anki-26.08-linux-x86_64.tar.zst`, run the included `anki-linux/install.sh`, and leave `~/.local/share/Anki2` untouched so collections and add-ons survive the upgrade.

The bootstrap test must assert the new release URL/archive layout. After the repository test passes, run the same bootstrap installer on this machine and verify `anki --version` reports 26.08.
