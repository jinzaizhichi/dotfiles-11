# Yomitan Local Audio Cache Design

The Japanese-study setup must check the installed Local Audio Server add-on data at `$XDG_DATA_HOME/Anki2/addons21/1045800357/user_files`, not require a source archive in `~/Downloads`. Missing audio is reported with the explicit downloader command but does not fail or start a large download.

`scripts/optional/download-yomitan-audio.sh` downloads the recommended Ogg/Opus torrent from Nyaa item 1681655 using its documented magnet and the already-installed `aria2c`. It stores the 2.5 GiB archive under `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/yomitan-audio`, validates that the archive contains `user_files`, and extracts it into add-on 1045800357. If installed audio data already exists, it exits without downloading.
