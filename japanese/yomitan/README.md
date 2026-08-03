# Yomitan

The repository carries the selected dictionary archives and the latest exported Yomitan configuration.

From the repository root, restore any missing archives:

```sh
./scripts/optional/japanese/download-yomitan-dictionaries.sh
```

The numbered filenames in `dictionaries.txt` define the import order. Jitendex, JPDB, and KANJIDIC use official sources from Yomitan's recommended catalog; the remaining archives come from MarvNC's or TheMoeWay's collection. The no-image build of 旺文社国語辞典 keeps the monolingual entry text without carrying its 118 MiB image payload.

1. Import the eight archives from `dictionaries/` through **Dictionaries → Configure installed and enabled dictionaries → Import**.
2. Import `settings.json` through **Settings → Backup → Import Settings**.
3. Open the options-page developer console, paste `sort-dictionaries.js`, and press Enter.

The sorter updates only the active profile, preserves dictionary settings, and leaves unrecognized dictionaries at the end. Finally, verify that Anki integration is enabled.

For an existing installation, delete `小学館例解学習国語 第十二版`, import the slot-03 `旺文社国語辞典` archive, and rerun the sorter.
