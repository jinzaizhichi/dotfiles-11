#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

mkdir -p \
    "$temp_dir/home/.config/nvim" \
    "$temp_dir/home/.local/bin" \
    "$temp_dir/config/nvim" \
    "$temp_dir/config/systemd/user" \
    "$temp_dir/config/ty"
touch "$temp_dir/home/.local/bin/existing-command"
printf '{"keep":true}\n' >"$temp_dir/config/ty/ty-receipt.json"
ln -s "$repo" "$temp_dir/home/dotfiles"
ln -s "$repo/.profile" "$temp_dir/home/.profile"
ln -s "$repo/xdg/readline" "$temp_dir/config/readline"
ln -s "$repo/xdg/new-tab/new-tab.service" \
    "$temp_dir/config/systemd/user/new-tab.service"
printf 'old unit\n' >"$temp_dir/config/systemd/user/kanata.service"

HOME="$temp_dir/home" XDG_CONFIG_HOME="$temp_dir/config" \
    "$repo/scripts/bootstrap/link-configs.sh" >/dev/null

test "$(readlink "$temp_dir/config/readline")" = "$repo/configs/xdg/readline"
test "$(readlink "$temp_dir/config/fd")" = "$repo/configs/xdg/fd"
test "$(readlink "$temp_dir/config/mpv")" = "$repo/configs/xdg/mpv"
test "$(readlink "$temp_dir/config/fontconfig")" = "$repo/configs/xdg/fontconfig"
test "$(readlink "$temp_dir/config/firefox")" = "$repo/configs/xdg/firefox"
test "$(readlink "$temp_dir/config/new-tab")" = "$repo/configs/xdg/new-tab"
test "$(readlink "$temp_dir/config/kanata")" = "$repo/configs/xdg/kanata"
test "$(readlink "$temp_dir/config/mise")" = "$repo/configs/xdg/mise"
test "$(readlink "$temp_dir/config/ty/ty.toml")" = "$repo/configs/xdg/ty/ty.toml"
test "$(readlink "$temp_dir/home/.profile")" = "$repo/configs/home/profile"
test "$(readlink "$temp_dir/config/systemd/user/new-tab.service")" = \
    "$repo/configs/xdg/new-tab/new-tab.service"
test "$(readlink "$temp_dir/config/systemd/user/kanata.service")" = \
    "$repo/configs/xdg/kanata/kanata.service"
grep -Fqx 'old unit' "$temp_dir/config/systemd/user/kanata.service-old"
test ! -e "$temp_dir/config/readline-old" && test ! -L "$temp_dir/config/readline-old"
test ! -e "$temp_dir/home/.profile-old" && test ! -L "$temp_dir/home/.profile-old"
grep -Fqx '{"keep":true}' "$temp_dir/config/ty/ty-receipt.json"
test ! -e "$temp_dir/config/ty-old"
test -f "$temp_dir/config/new-tab/blank.html"
test -f "$temp_dir/config/new-tab/background.webp"
test -f "$temp_dir/config/new-tab/new-tab.service"
test -f "$temp_dir/config/kanata/kanata.service"
grep -Fq 'background.webp' "$temp_dir/config/new-tab/blank.html"
grep -Fq 'background-size: cover' "$temp_dir/config/new-tab/blank.html"
grep -Fq 'background-position: right center' "$temp_dir/config/new-tab/blank.html"
grep -Fq 'http.server 8766 --bind 127.0.0.1' "$temp_dir/config/new-tab/new-tab.service"
grep -Fq \
    'ExecStart=%h/.local/share/mise/shims/kanata --cfg %h/.config/kanata/kanata.kbd' \
    "$temp_dir/config/kanata/kanata.service"
test "$(readlink "$temp_dir/config/VSCodium/User/settings.json")" = "$repo/configs/xdg/codium/settings.json"
test "$(readlink "$temp_dir/config/VSCodium/User/keybindings.json")" = "$repo/configs/xdg/codium/keybindings.json"
test ! -e "$temp_dir/config/codium"
test -f "$temp_dir/home/.local/bin/existing-command"
test "$(readlink "$temp_dir/home/.local/bin/appgate")" = "$repo/bin/appgate"
test "$(readlink "$temp_dir/home/.local/bin/codium")" = "$repo/bin/codium"
test "$(readlink "$temp_dir/home/.local/bin/fd")" = "$repo/bin/fd"
test "$(readlink "$temp_dir/home/.local/bin/rg")" = "$repo/bin/rg"
test "$(readlink "$temp_dir/home/.local/bin/steam")" = "$repo/bin/steam"
"$temp_dir/home/.local/bin/fd" --version | grep -Fq 'fdfind '
test "$(find "$repo/bin" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)" = \
    $'appgate\ncodium\nfd\nrg\nsteam'

appgate_test="$temp_dir/appgate"
mkdir -p "$appgate_test/bin" "$appgate_test/data"
cat >"$appgate_test/bin/real-appgate" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$HOME" "$*"
EOF
chmod +x "$appgate_test/bin/real-appgate"
output="$(XDG_DATA_HOME="$appgate_test/data" \
    APPGATE_BIN="$appgate_test/bin/real-appgate" \
    "$repo/bin/appgate" --url=appgate://example)"
test "$output" = "$appgate_test/data/appgate/home
--url=appgate://example"
test -d "$appgate_test/data/appgate/home"
grep -Fqx 'exec "${APPGATE_BIN:-/usr/bin/appgate.vendor}" "$@"' \
    "$repo/bin/appgate"

steam_test="$temp_dir/steam"
mkdir -p "$steam_test/data/fixsteam"
cat >"$steam_test/data/fixsteam/steam" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$*" >"$STEAM_TEST_LAUNCH_LOG"
EOF
chmod +x "$steam_test/data/fixsteam/steam"

STEAM_TEST_LAUNCH_LOG="$steam_test/launch.log" \
    XDG_DATA_HOME="$steam_test/data" \
    "$repo/bin/steam" 'argument with spaces' steam://open/games
grep -Fqx 'argument with spaces steam://open/games' "$steam_test/launch.log"

mkdir -p "$temp_dir/search/node_modules"
mkdir -p "$temp_dir/search/venv"
printf 'visible needle\n' >"$temp_dir/search/needle-visible.txt"
printf 'hidden needle\n' >"$temp_dir/search/node_modules/needle-hidden.txt"
printf 'venv needle\n' >"$temp_dir/search/venv/needle-venv.txt"
XDG_CONFIG_HOME="$temp_dir/config" \
    "$temp_dir/home/.local/bin/rg" needle "$temp_dir/search" \
    >"$temp_dir/rg-results"
grep -Fq 'visible needle' "$temp_dir/rg-results"
if grep -Fq 'hidden needle' "$temp_dir/rg-results"; then
    echo 'rg ignored the shared fd ignore file' >&2
    exit 1
fi
if grep -Fq 'venv needle' "$temp_dir/rg-results"; then
    echo 'rg searched the Python virtual environment' >&2
    exit 1
fi

XDG_CONFIG_HOME="$temp_dir/config" \
    fdfind --hidden --no-ignore-vcs needle "$temp_dir/search" \
    >"$temp_dir/fd-results"
grep -Fq 'needle-visible.txt' "$temp_dir/fd-results"
if grep -Fq 'needle-hidden.txt' "$temp_dir/fd-results"; then
    echo 'fd ignored its global ignore file' >&2
    exit 1
fi
if grep -Fq 'needle-venv.txt' "$temp_dir/fd-results"; then
    echo 'fd searched the Python virtual environment' >&2
    exit 1
fi

git -c core.excludesFile="$repo/configs/xdg/git/ignore" \
    -C "$temp_dir/search" init -q
git -c core.excludesFile="$repo/configs/xdg/git/ignore" \
    -C "$temp_dir/search" check-ignore -q venv/needle-venv.txt

HOME="$temp_dir/home" XDG_CONFIG_HOME="$temp_dir/config" \
    "$repo/scripts/bootstrap/link-configs.sh" >/dev/null
test ! -e "$temp_dir/home/.profile-old"

mkdir -p "$temp_dir/collision-home/.config/nvim"
printf 'keep me\n' >"$temp_dir/collision-home/.profile"
printf 'older backup\n' >"$temp_dir/collision-home/.profile-old"

if HOME="$temp_dir/collision-home" XDG_CONFIG_HOME="$temp_dir/collision-home/.config" \
    "$repo/scripts/bootstrap/link-configs.sh" >/dev/null 2>&1; then
    echo "installer overwrote an existing backup" >&2
    exit 1
fi

grep -qx 'keep me' "$temp_dir/collision-home/.profile"
grep -qx 'older backup' "$temp_dir/collision-home/.profile-old"

firefox_root="$temp_dir/firefox-home/.config/mozilla/firefox"
mkdir -p \
    "$firefox_root/Profiles/test.default-release/chrome" \
    "$temp_dir/firefox-home/.config"
ln -s "$repo/configs/xdg/firefox" "$temp_dir/firefox-home/.config/firefox"
printf 'old user.js\n' >"$firefox_root/Profiles/test.default-release/user.js"
printf 'old userContent.css\n' \
    >"$firefox_root/Profiles/test.default-release/chrome/userContent.css"
cat >"$firefox_root/profiles.ini" <<'EOF'
[Installtest]
Default=Profiles/test.default-release
Locked=1
EOF

HOME="$temp_dir/firefox-home" \
    XDG_CONFIG_HOME="$temp_dir/firefox-home/.config" \
    "$repo/scripts/optional/firefox/configure-profile.sh" >/dev/null

test "$(readlink "$firefox_root/Profiles/test.default-release/user.js")" = \
    "$repo/configs/xdg/firefox/user.js"
test "$(readlink "$firefox_root/Profiles/test.default-release/chrome/userContent.css")" = \
    "$repo/configs/xdg/firefox/chrome/userContent.css"
grep -qx 'old user.js' "$firefox_root/Profiles/test.default-release/user.js-old"
grep -qx 'old userContent.css' \
    "$firefox_root/Profiles/test.default-release/chrome/userContent.css-old"
grep -Fq 'regexp("^moz-extension://.*/html/newtab[.]html$")' \
    "$firefox_root/Profiles/test.default-release/chrome/userContent.css"
grep -Fq 'background-color: #1c1b22 !important;' \
    "$firefox_root/Profiles/test.default-release/chrome/userContent.css"

legacy_root="$temp_dir/legacy-firefox-home/.mozilla/firefox"
mkdir -p \
    "$legacy_root/Profiles/test.default-release" \
    "$temp_dir/legacy-firefox-home/.config"
ln -s "$repo/configs/xdg/firefox" "$temp_dir/legacy-firefox-home/.config/firefox"
cat >"$legacy_root/profiles.ini" <<'EOF'
[Installtest]
Default=Profiles/test.default-release
Locked=1
EOF

HOME="$temp_dir/legacy-firefox-home" \
    XDG_CONFIG_HOME="$temp_dir/legacy-firefox-home/.config" \
    "$repo/scripts/optional/firefox/configure-profile.sh" >/dev/null

test "$(readlink "$legacy_root/Profiles/test.default-release/user.js")" = \
    "$repo/configs/xdg/firefox/user.js"
test "$(readlink "$legacy_root/Profiles/test.default-release/chrome/userContent.css")" = \
    "$repo/configs/xdg/firefox/chrome/userContent.css"

mkdir -p \
    "$temp_dir/fake-bin" \
    "$temp_dir/setup-home"

cat >"$temp_dir/fake-bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$BOOTSTRAP_LOG"
EOF
chmod +x "$temp_dir/fake-bin/sudo"

cat >"$temp_dir/fake-bin/git" <<'EOF'
#!/usr/bin/env bash
[ -z "${GIT_TEST_LOG:-}" ] || printf '%s\n' "$*" >>"$GIT_TEST_LOG"
destination="${!#}"
test -d "$(dirname "$destination")"
mkdir "$destination"
case "$destination" in
    */zinit.git) touch "$destination/zinit.zsh" ;;
    */mpvacious)
        mkdir -p "$destination/mpvacious"
        printf '    max_shown_line_length = 30,\n' >"$destination/mpvacious/main.lua"
        printf '{"version": "v26.7.13.0"}' >"$destination/mpvacious/version.json"
        ;;
esac
EOF
chmod +x "$temp_dir/fake-bin/git"

cat >"$temp_dir/fake-bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_TEST_LOG"
cat <<'INSTALLER'
mkdir -p "$(dirname "$MISE_INSTALL_PATH")"
cat >"$MISE_INSTALL_PATH" <<'MISE'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MISE_TEST_LOG"
MISE
chmod +x "$MISE_INSTALL_PATH"
INSTALLER
EOF
chmod +x "$temp_dir/fake-bin/curl"

cat >"$temp_dir/fake-bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"
EOF
chmod +x "$temp_dir/fake-bin/systemctl"

cat >"$temp_dir/fake-bin/gsettings" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = list-schemas ]; then
    printf '%s\n' \
        org.cinnamon.desktop.input-sources \
        org.cinnamon.desktop.peripherals.keyboard \
        org.freedesktop.ibus.general \
        org.gnome.libgnomekbd.keyboard
else
    printf '%s\n' "$*" >>"$GSETTINGS_LOG"
fi
EOF
chmod +x "$temp_dir/fake-bin/gsettings"

cat >"$temp_dir/fake-bin/kwriteconfig6" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$KWRITECONFIG_LOG"
EOF
chmod +x "$temp_dir/fake-bin/kwriteconfig6"

cat >"$temp_dir/fake-bin/setxkbmap" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$XKB_TEST_LOG"
EOF
chmod +x "$temp_dir/fake-bin/setxkbmap"

cat >"$temp_dir/ubuntu-24.04" <<'EOF'
ID=ubuntu
VERSION_ID="24.04"
EOF
cat >"$temp_dir/ubuntu-26.04" <<'EOF'
ID=ubuntu
VERSION_ID="26.04"
EOF

SYSTEMCTL_LOG="$temp_dir/systemctl.log" \
    HOME="$temp_dir/home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CONFIG_HOME="$temp_dir/config" \
    "$repo/scripts/optional/firefox/configure-new-tab.sh" >/dev/null

grep -Fqx -- '--user daemon-reload' "$temp_dir/systemctl.log"
grep -qx -- '--user enable --now new-tab.service' "$temp_dir/systemctl.log"

BOOTSTRAP_LOG="$temp_dir/kanata-sudo.log" \
    SYSTEMCTL_LOG="$temp_dir/kanata-systemctl.log" \
    HOME="$temp_dir/home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CONFIG_HOME="$temp_dir/config" \
    "$repo/scripts/optional/system/configure-kanata.sh" >/dev/null

grep -Fqx -- '--user daemon-reload' "$temp_dir/kanata-systemctl.log"
grep -Fqx -- '--user enable kanata.service' \
    "$temp_dir/kanata-systemctl.log"
grep -Fqx -- '--user restart kanata.service' \
    "$temp_dir/kanata-systemctl.log"

BOOTSTRAP_LOG="$temp_dir/sudo.log" \
    CURL_TEST_LOG="$temp_dir/curl.log" \
    GSETTINGS_LOG="$temp_dir/gsettings.log" \
    MISE_TEST_LOG="$temp_dir/mise.log" \
    OS_RELEASE_FILE="$temp_dir/ubuntu-24.04" \
    XKB_TEST_LOG="$temp_dir/xkb.log" \
    DISPLAY=:99 \
    HOME="$temp_dir/setup-home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=X-Cinnamon \
    XDG_CONFIG_HOME="$temp_dir/setup-home/.config" \
    XDG_DATA_HOME="$temp_dir/setup-home/.local/share" \
    "$repo/scripts/setup.sh" >/dev/null

grep -qx 'apt-get update' "$temp_dir/sudo.log"
grep -q '^apt-get install -y ' "$temp_dir/sudo.log"
grep -Fqx -- '--fail --silent --show-error --location https://mise.run' \
    "$temp_dir/curl.log"
grep -Fqx \
    'install --yes rust uv lazygit lazydocker shfmt k9s github:zk-org/zk github:ewhauser/shuck bob github:jtroo/kanata' \
    "$temp_dir/mise.log"
grep -Fqx 'exec -- bob use nightly' "$temp_dir/mise.log"
if grep -q 'pipewire-audio-client-libraries' "$temp_dir/sudo.log"; then
    echo "default bootstrap would replace the existing audio stack" >&2
    exit 1
fi
test "$(readlink "$temp_dir/setup-home/.profile")" = "$repo/configs/home/profile"
test ! -L "$temp_dir/setup-home/.xprofile"
grep -Fqx 'reset org.gnome.libgnomekbd.keyboard layouts' \
    "$temp_dir/gsettings.log"
grep -Fqx 'reset org.gnome.libgnomekbd.keyboard options' \
    "$temp_dir/gsettings.log"
grep -Fqx 'reset org.gnome.libgnomekbd.keyboard model' \
    "$temp_dir/gsettings.log"
grep -Fqx 'reset org.cinnamon.desktop.input-sources sources' \
    "$temp_dir/gsettings.log"
grep -Fqx 'reset org.cinnamon.desktop.input-sources xkb-options' \
    "$temp_dir/gsettings.log"
grep -Fqx 'set org.cinnamon.desktop.peripherals.keyboard delay 220' \
    "$temp_dir/gsettings.log"
grep -Fqx 'set org.cinnamon.desktop.peripherals.keyboard repeat-interval 25' \
    "$temp_dir/gsettings.log"
grep -Fqx 'set org.freedesktop.ibus.general use-system-keyboard-layout true' \
    "$temp_dir/gsettings.log"
test -f "$repo/configs/system/keyboard"
grep -Fqx 'XKBMODEL="pc105"' "$repo/configs/system/keyboard"
grep -Fqx 'XKBLAYOUT="us,ru"' "$repo/configs/system/keyboard"
grep -Fqx 'XKBVARIANT=","' "$repo/configs/system/keyboard"
grep -Fqx 'XKBOPTIONS="grp:alt_shift_toggle"' "$repo/configs/system/keyboard"
grep -Fqx "install -m 644 $repo/configs/system/keyboard /etc/default/keyboard" \
    "$temp_dir/sudo.log"
grep -Fqx -- '-layout us,ru -variant , -option  -option grp:alt_shift_toggle' \
    "$temp_dir/xkb.log"

mkdir -p "$temp_dir/setup-kde-home"
BOOTSTRAP_LOG="$temp_dir/kde-setup-sudo.log" \
    CURL_TEST_LOG="$temp_dir/kde-setup-curl.log" \
    KWRITECONFIG_LOG="$temp_dir/kde-setup-kwriteconfig.log" \
    MISE_TEST_LOG="$temp_dir/kde-setup-mise.log" \
    OS_RELEASE_FILE="$temp_dir/ubuntu-26.04" \
    DISPLAY= \
    HOME="$temp_dir/setup-kde-home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=KDE \
    XDG_CONFIG_HOME="$temp_dir/setup-kde-home/.config" \
    XDG_DATA_HOME="$temp_dir/setup-kde-home/.local/share" \
    "$repo/scripts/setup.sh" >/dev/null
grep -Fqx -- '--file kxkbrc --group Layout --key LayoutList us,ru' \
    "$temp_dir/kde-setup-kwriteconfig.log"
grep -Eq '^apt-get install -y .*libncurses-dev' \
    "$temp_dir/kde-setup-sudo.log"
if grep -Eq '^apt-get install -y .*libncursesw5-dev' \
    "$temp_dir/kde-setup-sudo.log"; then
    echo 'Kubuntu setup requested removed libncursesw5-dev' >&2
    exit 1
fi

mkdir -p "$temp_dir/unsupported-home"
: >"$temp_dir/unsupported-sudo.log"
if BOOTSTRAP_LOG="$temp_dir/unsupported-sudo.log" \
    CURL_TEST_LOG="$temp_dir/unsupported-curl.log" \
    GSETTINGS_LOG="$temp_dir/unsupported-gsettings.log" \
    MISE_TEST_LOG="$temp_dir/unsupported-mise.log" \
    OS_RELEASE_FILE="$temp_dir/ubuntu-26.04" \
    XKB_TEST_LOG="$temp_dir/unsupported-xkb.log" \
    DISPLAY=:99 \
    HOME="$temp_dir/unsupported-home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=X-Cinnamon \
    XDG_CONFIG_HOME="$temp_dir/unsupported-home/.config" \
    XDG_DATA_HOME="$temp_dir/unsupported-home/.local/share" \
    "$repo/scripts/setup.sh" >/dev/null 2>&1; then
    echo 'Bootstrap accepted Ubuntu 26.04 with Cinnamon' >&2
    exit 1
fi
test ! -s "$temp_dir/unsupported-sudo.log"
test ! -e "$temp_dir/unsupported-home/.profile"

KWRITECONFIG_LOG="$temp_dir/kwriteconfig.log" \
    BOOTSTRAP_LOG="$temp_dir/kde-sudo.log" \
    DISPLAY= \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=KDE \
    "$repo/scripts/bootstrap/configure-desktop.sh"

for expected in \
    '--file kxkbrc --group Layout --key Use true' \
    '--file kxkbrc --group Layout --key ResetOldOptions true' \
    '--file kxkbrc --group Layout --key LayoutList us,ru' \
    '--file kxkbrc --group Layout --key VariantList ,' \
    '--file kxkbrc --group Layout --key Options grp:alt_shift_toggle' \
    '--file kcminputrc --group Keyboard --key KeyRepeat repeat' \
    '--file kcminputrc --group Keyboard --key RepeatDelay 220' \
    '--file kcminputrc --group Keyboard --key RepeatRate 40'; do
    grep -Fqx -- "$expected" "$temp_dir/kwriteconfig.log"
done

keyboard_repo="$temp_dir/keyboard-repo"
mkdir -p "$keyboard_repo/scripts/bootstrap" "$keyboard_repo/configs/system"
cp "$repo/scripts/bootstrap/configure-desktop.sh" \
    "$keyboard_repo/scripts/bootstrap/configure-desktop.sh"
cat >"$keyboard_repo/configs/system/keyboard" <<'EOF'
XKBMODEL="pc105"
XKBLAYOUT="us,ru,de"
XKBVARIANT=",,"
XKBOPTIONS="grp:alt_shift_toggle"
BACKSPACE="guess"
EOF
KWRITECONFIG_LOG="$temp_dir/custom-keyboard.log" \
    BOOTSTRAP_LOG="$temp_dir/custom-keyboard-sudo.log" \
    DISPLAY= \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=KDE \
    "$keyboard_repo/scripts/bootstrap/configure-desktop.sh"
grep -Fqx -- '--file kxkbrc --group Layout --key LayoutList us,ru,de' \
    "$temp_dir/custom-keyboard.log"
grep -Fqx -- '--file kxkbrc --group Layout --key VariantList ,,' \
    "$temp_dir/custom-keyboard.log"

KWRITECONFIG_LOG="$temp_dir/unknown-kwriteconfig.log" \
    BOOTSTRAP_LOG="$temp_dir/unknown-sudo.log" \
    DISPLAY= \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CURRENT_DESKTOP=sway \
    "$repo/scripts/bootstrap/configure-desktop.sh"
test ! -e "$temp_dir/unknown-kwriteconfig.log"

cat >"$temp_dir/fake-bin/dpkg-divert" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = --truename ]; then
    printf '%s\n' "$2"
fi
EOF
chmod +x "$temp_dir/fake-bin/dpkg-divert"

BOOTSTRAP_LOG="$temp_dir/appgate-system.log" \
    PATH="$temp_dir/fake-bin:$PATH" \
    "$repo/scripts/optional/system/configure-appgate-xdg.sh"
grep -Fqx \
    'dpkg-divert --quiet --local --add --rename --divert /usr/bin/appgate.vendor /usr/bin/appgate' \
    "$temp_dir/appgate-system.log"
grep -Fqx \
    "install -m 755 $repo/bin/appgate /usr/bin/appgate" \
    "$temp_dir/appgate-system.log"

sudo_test="$temp_dir/sudo-provider"
mkdir -p "$sudo_test/bin"
cat >"$sudo_test/bin/sudo" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = --version ]; then
    printf '%s\n' "$SUDO_TEST_VERSION"
    exit
fi
printf '%s\n' "$*" >>"$SUDO_TEST_LOG"
if [ "${1:-}" = tee ]; then
    cat >"$2"
fi
EOF
chmod +x "$sudo_test/bin/sudo"

: >"$sudo_test/sudo-rs.log"
sudo_rs_output="$(
    BASHRC_FILE="$sudo_test/sudo-rs-bashrc" \
        PATH="$sudo_test/bin:$PATH" \
        SUDO_ADMIN_FLAG_FILE="$sudo_test/sudo-rs-admin-flag" \
        SUDO_TEST_LOG="$sudo_test/sudo-rs.log" \
        SUDO_TEST_VERSION='sudo-rs 0.2.13' \
        "$repo/scripts/optional/system/disable-sudo-admin-flag.sh"
)"
test "$sudo_rs_output" = \
    'sudo-rs does not create ~/.sudo_as_admin_successful; nothing to configure.'
test ! -s "$sudo_test/sudo-rs.log"
test ! -e "$sudo_test/sudo-rs-admin-flag"

printf 'sudo_as_admin_successful\n' >"$sudo_test/classic-bashrc"
: >"$sudo_test/classic.log"
BASHRC_FILE="$sudo_test/classic-bashrc" \
    PATH="$sudo_test/bin:$PATH" \
    SUDO_ADMIN_FLAG_FILE="$sudo_test/classic-admin-flag" \
    SUDO_TEST_LOG="$sudo_test/classic.log" \
    SUDO_TEST_VERSION='Sudo version 1.9.15p5' \
    "$repo/scripts/optional/system/disable-sudo-admin-flag.sh" >/dev/null
grep -Fqx 'tee '"$sudo_test/classic-admin-flag" "$sudo_test/classic.log"
grep -Fqx 'Defaults !admin_flag' "$sudo_test/classic-admin-flag"

expected_scripts=(
    scripts/bootstrap/configure-desktop.sh
    scripts/bootstrap/install-mise.sh
    scripts/bootstrap/install-packages.sh
    scripts/bootstrap/link-configs.sh
    scripts/optional/desktop/import-gnome-terminal-profile.sh
    scripts/optional/desktop/install-steam.sh
    scripts/optional/desktop/install-ubuntu-mono-nerd-font.sh
    scripts/optional/desktop/lightdm/configure-xauthority.sh
    scripts/optional/desktop/lightdm/patch-binary.sh
    scripts/optional/firefox/configure-profile.sh
    scripts/optional/firefox/configure-new-tab.sh
    scripts/optional/firefox/install.sh
    scripts/optional/firefox/patch-keybindings.sh
    scripts/optional/japanese/download-yomitan-audio.sh
    scripts/optional/japanese/download-yomitan-dictionaries.sh
    scripts/optional/japanese/setup.sh
    scripts/optional/japanese/update-japanese-sentences.sh
    scripts/optional/shell/configure-bash-xdg.sh
    scripts/optional/shell/install-codex.sh
    scripts/optional/shell/set-default-zsh.sh
    scripts/optional/system/configure-kanata.sh
    scripts/optional/system/configure-appgate-xdg.sh
    scripts/optional/system/configure-ssh-xdg.sh
    scripts/optional/system/disable-snap.sh
    scripts/optional/system/disable-sudo-admin-flag.sh
)
for script in "${expected_scripts[@]}"; do
    test -x "$repo/$script"
    case "$script" in
        scripts/optional/*)
            grep -Fq "\`${script#scripts/optional/}\`" "$repo/README.md"
            ;;
    esac
done

for heading in \
    '## Fresh-machine runbook' \
    '## Repository map' \
    '### Configurations and study resources' \
    '### Automatic bootstrap' \
    '### Manual setup' \
    '### Wrapper' \
    '### Test' \
    '### Downloaded/vendor content'; do
    grep -Fqx "$heading" "$repo/README.md"
done
grep -Fq './tests/bootstrap.sh' "$repo/README.md"

profile_home="$temp_dir/profile-home"
mkdir -p "$profile_home"
profile_compinit="$(
    env -u skip_global_compinit HOME="$profile_home" sh -c \
        '. "$1"; printf "%s" "$skip_global_compinit"' \
        sh "$repo/configs/home/profile"
)"
test "$profile_compinit" = 1

codex_test="$temp_dir/codex-home"
codex_release=0.146.0-x86_64-unknown-linux-musl
codex_release_dir="$codex_test/home/.codex/packages/standalone/releases/$codex_release"
mkdir -p \
    "$codex_release_dir/bin" \
    "$codex_test/home/.local/bin" \
    "$codex_test/data" \
    "$codex_test/bin"
printf 'model = "test"\n' >"$codex_test/home/.codex/config.toml"
printf '#!/bin/sh\n' >"$codex_release_dir/bin/codex"
chmod +x "$codex_release_dir/bin/codex"
ln -s "$codex_release_dir" \
    "$codex_test/home/.codex/packages/standalone/current"
ln -s "$codex_test/home/.codex/packages/standalone/current/bin/codex" \
    "$codex_test/home/.local/bin/codex"
cat >"$codex_test/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$codex_test/home/.local/bin/mise" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$CODEX_HOME" >"$CODEX_TEST_HOME_LOG"
printf '%s\n' "$*" >>"$CODEX_TEST_MISE_LOG"
EOF
chmod +x "$codex_test/bin/pgrep" "$codex_test/home/.local/bin/mise"

HOME="$codex_test/home" \
    CODEX_TEST_HOME_LOG="$codex_test/codex-home.log" \
    CODEX_TEST_MISE_LOG="$codex_test/mise.log" \
    XDG_DATA_HOME="$codex_test/data" \
    PATH="$codex_test/bin:$PATH" \
    "$repo/scripts/optional/shell/install-codex.sh" >/dev/null
test ! -e "$codex_test/home/.codex"
grep -Fqx 'model = "test"' "$codex_test/data/codex/config.toml"
test ! -L "$codex_test/home/.local/bin/codex"
grep -Fqx "$codex_test/data/codex" "$codex_test/codex-home.log"
grep -Fqx 'exec -- npm install --global @openai/codex@latest' "$codex_test/mise.log"
grep -Fqx 'reshim' "$codex_test/mise.log"

mkdir -p "$codex_test/home/.codex"
printf 'preserve source\n' >"$codex_test/home/.codex/source"
if HOME="$codex_test/home" XDG_DATA_HOME="$codex_test/data" \
    PATH="$codex_test/bin:$PATH" \
    "$repo/scripts/optional/shell/install-codex.sh" >/dev/null 2>&1; then
    echo 'Codex installation overwrote an existing destination' >&2
    exit 1
fi
grep -qx 'preserve source' "$codex_test/home/.codex/source"

codex_active_test="$temp_dir/codex-active"
mkdir -p "$codex_active_test/home/.codex" "$codex_active_test/data" "$codex_active_test/bin"
printf 'still active\n' >"$codex_active_test/home/.codex/config.toml"
cat >"$codex_active_test/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$codex_active_test/bin/pgrep"
if HOME="$codex_active_test/home" XDG_DATA_HOME="$codex_active_test/data" \
    PATH="$codex_active_test/bin:$PATH" \
    "$repo/scripts/optional/shell/install-codex.sh" >/dev/null 2>&1; then
    echo 'Codex installation ran while Codex was active' >&2
    exit 1
fi
grep -qx 'still active' "$codex_active_test/home/.codex/config.toml"

ssh_test="$temp_dir/ssh-xdg"
mkdir -p "$ssh_test/home/.config/ssh" "$ssh_test/home/.ssh" "$ssh_test/bin"
cat >"$ssh_test/home/.config/ssh/config" <<'EOF'
Host *
    IdentityFile ~/.config/ssh/id_rsa
    UserKnownHostsFile ~/.config/ssh/known_hosts
EOF
printf 'existing\nshared\n' >"$ssh_test/home/.config/ssh/known_hosts"
printf 'shared\nnew\n' >"$ssh_test/home/.ssh/known_hosts"
printf 'obsolete\n' >"$ssh_test/home/.ssh/known_hosts.old"
cat >"$ssh_test/bin/sudo" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = tee ]; then
    cat >"$SSH_TEST_SYSTEM_CONFIG"
    exit
fi
exec "$@"
EOF
cat >"$ssh_test/bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'userknownhostsfile %s/.config/ssh/known_hosts\n' "$HOME"
EOF
chmod +x "$ssh_test/bin/sudo" "$ssh_test/bin/ssh"

HOME="$ssh_test/home" \
    PATH="$ssh_test/bin:$PATH" \
    SSH_TEST_SYSTEM_CONFIG="$ssh_test/system.conf" \
    XDG_CONFIG_HOME="$ssh_test/home/.config" \
    "$repo/scripts/optional/system/configure-ssh-xdg.sh" >/dev/null
grep -Fqx "Include \"$ssh_test/home/.config/ssh/config\"" "$ssh_test/system.conf"
test "$(sort "$ssh_test/home/.config/ssh/known_hosts")" = $'existing\nnew\nshared'
test ! -e "$ssh_test/home/.ssh"

test -f "$repo/configs/gnome-terminal/profile.dconf"
grep -Fq "\"\$dotfiles/configs/gnome-terminal/profile.dconf\"" \
    "$repo/scripts/optional/desktop/import-gnome-terminal-profile.sh"

snap_test="$temp_dir/snap-test"
mkdir -p "$snap_test/bin" "$snap_test/home/snap/firefox" "$snap_test/trash"
printf 'keep me\n' >"$snap_test/home/snap/firefox/data"
cat >"$snap_test/bin/snap" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = list ]; then
    cat <<'SNAPS'
Name        Version  Rev  Tracking       Publisher   Notes
SNAPS
    cat "$SNAP_TEST_STATE"
fi
EOF
chmod +x "$snap_test/bin/snap"
cat >"$snap_test/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SNAP_TEST_LOG"
if [ "${1:-}" = snap ] && [ "${2:-}" = remove ]; then
    name="${4:-}"
    if [ "$name" = gtk-common-themes ] && grep -q '^snap-store ' "$SNAP_TEST_STATE"; then
        exit 1
    fi
    awk -v name="$name" '$1 != name' "$SNAP_TEST_STATE" >"$SNAP_TEST_STATE.tmp"
    mv "$SNAP_TEST_STATE.tmp" "$SNAP_TEST_STATE"
    if [ -e "$HOME/snap/$name" ]; then
        mv "$HOME/snap/$name" "$SNAP_TEST_TRASH/"
    fi
fi
if [ "${1:-}" = tee ]; then
    cat >"$SNAP_TEST_PIN"
fi
EOF
chmod +x "$snap_test/bin/sudo"
cat >"$snap_test/state" <<'EOF'
firefox           1  1  latest/stable  canonical  -
gtk-common-themes 1  1  latest/stable  canonical  -
snap-store        1  1  latest/stable  canonical  -
spotify           1  1  latest/stable  spotify    classic
core24            1  1  latest/stable  canonical  base
snapd             1  1  latest/stable  canonical  snapd
EOF

SNAP_TEST_LOG="$snap_test/commands" \
    SNAP_TEST_PIN="$snap_test/pin" \
    SNAP_TEST_STATE="$snap_test/state" \
    SNAP_TEST_TRASH="$snap_test/trash" \
    HOME="$snap_test/home" \
    PATH="$snap_test/bin:$PATH" \
    "$repo/scripts/optional/system/disable-snap.sh" >/dev/null

grep -qx 'snap remove --purge firefox' "$snap_test/commands"
grep -qx 'snap remove --purge spotify' "$snap_test/commands"
test "$(grep -c '^snap remove --purge gtk-common-themes$' "$snap_test/commands")" -eq 2
grep -qx 'snap remove --purge core24' "$snap_test/commands"
grep -qx 'snap remove --purge snapd' "$snap_test/commands"
grep -qx 'apt-get purge -y snapd' "$snap_test/commands"
grep -qx 'Package: snapd' "$snap_test/pin"
grep -qx 'Pin-Priority: -10' "$snap_test/pin"
grep -qx 'keep me' "$snap_test/home/snap/firefox/data"

study_home="$temp_dir/study-home"
mkdir -p \
    "$study_home/opt/anki" \
    "$study_home/Downloads" \
    "$study_home/.config/mpv/scripts" \
    "$study_home/.local/share/Anki2/addons21/2055492159"
printf '26.08\n' >"$study_home/opt/anki/.version"

grep -Fqx 'VERSION="26.08"' "$repo/scripts/optional/japanese/setup.sh"
grep -Fqx 'ANKI_RELEASE="anki-linux"' "$repo/scripts/optional/japanese/setup.sh"
# shellcheck disable=SC2016 # Match the literal VERSION reference.
grep -Fqx 'ANKI_ARCHIVE="anki-${VERSION}-linux-x86_64.tar.zst"' \
    "$repo/scripts/optional/japanese/setup.sh"

study_output="$(
    GIT_TEST_LOG="$study_home/git.log" \
        HOME="$study_home" \
        PATH="$temp_dir/fake-bin:$PATH" \
        XDG_CONFIG_HOME="$study_home/.config" \
        XDG_DATA_HOME="$study_home/.local/share" \
        "$repo/scripts/optional/japanese/setup.sh"
)"

GIT_TEST_LOG="$study_home/git.log" \
    HOME="$study_home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CONFIG_HOME="$study_home/.config" \
    XDG_DATA_HOME="$study_home/.local/share" \
    "$repo/scripts/optional/japanese/setup.sh" >/dev/null

grep -q -- 'clone --depth 1 --branch v26.7.28.0 https://github.com/Ajatt-Tools/mpvacious' \
    "$study_home/git.log"
grep -qx '    max_shown_line_length = 300,' \
    "$study_home/.config/mpv/scripts/mpvacious/mpvacious/main.lua"
grep -Fqx '{"version": "v26.7.28.0"}' \
    "$study_home/.config/mpv/scripts/mpvacious/mpvacious/version.json"

missing_addons="$(printf '%s\n' "$study_output" | sed -n 's/^Missing AnkiWeb add-ons: //p')"
printf '%s\n' "$missing_addons" | grep -qw 1045800357
if printf '%s\n' "$missing_addons" | grep -qw 2055492159; then
    echo 'already installed Anki add-on was reported missing' >&2
    exit 1
fi
printf '%s\n' "$study_output" | grep -Fq \
    'Run download-yomitan-audio.sh after installing add-on 1045800357.'

audio_test="$temp_dir/audio-test"
mkdir -p \
    "$audio_test/Anki2/addons21/1045800357" \
    "$audio_test/cache" \
    "$audio_test/fixture/user_files/forvo_files" \
    "$audio_test/fixture/user_files/jpod_files" \
    "$audio_test/fixture/user_files/nhk16_files" \
    "$audio_test/fixture/user_files/shinmeikai8_files"
printf 'audio fixture\n' \
    >"$audio_test/fixture/user_files/nhk16_files/entry.opus"
printf '{}\n' >"$audio_test/fixture/user_files/jmdict_forms.json"
tar -cJf "$audio_test/fixture.tar.xz" \
    -C "$audio_test/fixture" user_files

cat >"$temp_dir/fake-bin/aria2c" <<'EOF'
#!/usr/bin/env bash
for argument in "$@"; do
    case "$argument" in
        --dir=*) destination="${argument#--dir=}" ;;
    esac
done
printf 'download\n' >>"$AUDIO_TEST_LOG"
cp "$AUDIO_TEST_ARCHIVE" \
    "$destination/local-yomichan-audio-collection-2023-06-11-opus.tar.xz"
EOF
chmod +x "$temp_dir/fake-bin/aria2c"

AUDIO_TEST_ARCHIVE="$audio_test/fixture.tar.xz" \
    AUDIO_TEST_LOG="$audio_test/aria2.log" \
    HOME="$audio_test/home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CACHE_HOME="$audio_test/cache" \
    XDG_DATA_HOME="$audio_test" \
    "$repo/scripts/optional/japanese/download-yomitan-audio.sh" >/dev/null

test -f "$audio_test/Anki2/addons21/1045800357/user_files/nhk16_files/entry.opus"
test -f "$audio_test/cache/dotfiles/yomitan-audio/local-yomichan-audio-collection-2023-06-11-opus.tar.xz"

AUDIO_TEST_ARCHIVE="$audio_test/fixture.tar.xz" \
    AUDIO_TEST_LOG="$audio_test/aria2.log" \
    HOME="$audio_test/home" \
    PATH="$temp_dir/fake-bin:$PATH" \
    XDG_CACHE_HOME="$audio_test/cache" \
    XDG_DATA_HOME="$audio_test" \
    "$repo/scripts/optional/japanese/download-yomitan-audio.sh" >/dev/null
test "$(wc -l <"$audio_test/aria2.log")" -eq 1

test -f "$repo/japanese/anki/addons.txt"
grep -Eq '^1344485230[[:space:]]+AJT Japanese$' "$repo/japanese/anki/addons.txt"
awk 'NF < 2 || $1 !~ /^[0-9]+$/ { exit 1 }' "$repo/japanese/anki/addons.txt" || {
    echo 'japanese/anki/addons.txt must contain a numeric code and name on each line' >&2
    exit 1
}
if rg -q 'Ajatt-Tools/Japanese' "$repo/scripts/optional/japanese/setup.sh"; then
    echo 'AJT Japanese should be installed from the AnkiWeb manifest' >&2
    exit 1
fi

dictionary_count=0
while IFS=$'\t' read -r source filename; do
    [ -n "$source" ] || continue
    case "$source" in \#*) continue ;; esac

    dictionary_count=$((dictionary_count + 1))
    dictionary="japanese/yomitan/dictionaries/$filename"
    test -f "$repo/$dictionary"
    test "$(stat -c %s "$repo/$dictionary")" -lt 100000000
    if git -C "$repo" check-ignore -q -- "$dictionary"; then
        echo "Tracked Yomitan dictionary is ignored: $dictionary" >&2
        exit 1
    fi
done <"$repo/japanese/yomitan/dictionaries.txt"
test "$dictionary_count" -eq 8

grep -qx 'snapshot_quality=40' "$repo/configs/xdg/mpv/script-opts/subs2srs.conf"
grep -qx 'secondary_sub_lang=ru,rus,eng,en,jp,jpn,ja' "$repo/configs/xdg/mpv/script-opts/subs2srs.conf"
grep -qx 'card_overwrite_safeguard=1' "$repo/configs/xdg/mpv/script-opts/subs2srs.conf"
grep -Fqx 'bookmark_save_keybind=["alt+b", "alt+B"]' \
    "$repo/configs/xdg/mpv/script-opts/SimpleBookmark.conf"

"$repo/tests/update-japanese-sentences.sh"
"$repo/tests/python-environment.sh"

test ! -e "$repo/configs/xdg/zsh/.zshenv"
test ! -e "$repo/configs/xdg/zsh/.zprofile"
test ! -e "$repo/configs/xdg/zsh/.zcompdump"
test ! -e "$repo/xdg"
test ! -e "$repo/desktop"
test ! -e "$repo/.profile"
grep -Fqx 'HISTFILE="$XDG_STATE_HOME/zsh/history"' "$repo/configs/xdg/zsh/.zshrc"
grep -Fqx 'ZINIT[ZCOMPDUMP_PATH]="$XDG_CACHE_HOME/zsh/zcompdump"' \
    "$repo/configs/xdg/zsh/.zshrc"
grep -Fqx 'export PATH="$XDG_DATA_HOME/mise/shims:$PATH"' "$repo/configs/home/profile"
grep -Fqx 'export PATH="$XDG_DATA_HOME/bob/nvim-bin:$PATH"' "$repo/configs/home/profile"
grep -Fqx 'export REDISCLI_HISTFILE="$XDG_STATE_HOME/redis/history"' "$repo/configs/home/profile"
grep -Fqx 'export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"' "$repo/configs/home/profile"
grep -Fqx 'export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"' "$repo/configs/home/profile"
grep -Fqx 'export CODEX_HOME="$XDG_DATA_HOME/codex"' "$repo/configs/home/profile"
grep -Fqx 'export NLTK_DATA="$XDG_DATA_HOME/nltk"' "$repo/configs/home/profile"
grep -Fqx 'export KUBECACHEDIR="$XDG_CACHE_HOME/kube"' "$repo/configs/home/profile"
test "$(grep '^export PATH=' "$repo/configs/home/profile" | tail -n 1)" = \
    'export PATH="$XDG_DATA_HOME/mise/shims:$PATH"'
if rg -q 'mise activate' "$repo/configs/xdg/zsh/.zshrc"; then
    echo 'Mise activation belongs in the inherited profile PATH' >&2
    exit 1
fi
if rg -q 'alias ssh=|SSH_CONFIG|sshCommand' \
    "$repo/configs/home/profile" "$repo/configs/xdg/zsh/.zshrc" "$repo/configs/xdg/git/config"; then
    echo 'SSH still depends on command-specific XDG overrides' >&2
    exit 1
fi
grep -Fqx \
    'alias ssh-copy-id='"'"'ssh-copy-id -i "$XDG_CONFIG_HOME/ssh/id_rsa"'"'"'' \
    "$repo/configs/xdg/zsh/.zshrc"
test "$(grep -Ec '^zinit light (chr-fritz/docker-completion[.]zshplugin|greymd/docker-zsh-completion)$' \
    "$repo/configs/xdg/zsh/.zshrc")" -eq 1
for command in rust uv lazygit lazydocker shfmt k9s zk shuck bob kanata; do
    grep -Eq "^${command}[[:space:]]*=" "$repo/configs/xdg/mise/config.toml" || \
        grep -Eq "github:[^\"]*/${command}\"" "$repo/configs/xdg/mise/config.toml"
done
if grep -Eq '^python[[:space:]]*=|^\[settings[.]python\]' \
    "$repo/configs/xdg/mise/config.toml"; then
    echo 'uv, not Mise, should manage development Python' >&2
    exit 1
fi
if rg -q 'jesseduffield/(lazygit|lazydocker)|JohnnyMorganz/StyLua|mvdan/sh|mikefarah/yq|derailed/k9s|zk-org/zk|ewhauser/shuck' \
    "$repo/configs/xdg/zsh/.zshrc"; then
    echo 'Zinit still manages a command-line tool' >&2
    exit 1
fi

find "$repo/scripts" -name '*.sh' -exec bash -n {} +
zsh -n "$repo/configs/xdg/zsh/.zshrc"
