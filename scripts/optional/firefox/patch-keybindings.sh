#!/bin/bash

set -euo pipefail

firefox_archive="${FIREFOX_ARCHIVE:-/usr/lib/firefox/browser/omni.ja}"
firefox_cache="${FIREFOX_CACHE:-$HOME/.cache/mozilla/firefox}"
if [ ! -r "$firefox_archive" ]; then
  echo "Firefox installation not found at $firefox_archive. Run scripts/optional/firefox/install.sh first." >&2
  exit 1
fi

tempdir=$(mktemp -d)
trap 'rm -rf "$tempdir"' EXIT
mkdir "$tempdir/extract"

# Firefox omni.ja files can make unzip return 1 for harmless warnings. Require
# the file we patch below instead of ignoring failures from the whole script.
unzip_status=0
unzip -q "$firefox_archive" -d "$tempdir/extract" || unzip_status=$?
if (( unzip_status > 1 )); then
  echo "Could not extract $firefox_archive (unzip status $unzip_status)." >&2
  exit "$unzip_status"
fi

browser_xhtml="$tempdir/extract/chrome/browser/content/browser/browser.xhtml"
if [ ! -f "$browser_xhtml" ]; then
  echo "Firefox browser.xhtml was not found in $firefox_archive." >&2
  exit 1
fi

# Only refresh the pristine backup when Firefox currently has its upstream
# navigation bindings. This preserves the new original after a Firefox update,
# but prevents a rerun from replacing it with our already-patched archive.
backup_pristine=false
if grep -q 'id="goBackKb"[^>]*keycode="VK_LEFT"' "$browser_xhtml" &&
   grep -q 'id="goForwardKb"[^>]*keycode="VK_RIGHT"' "$browser_xhtml"; then
  backup_pristine=true
fi

cat << EOF > "$tempdir/extract/chrome/browser/content/browser/blanktab.html"
<!DOCTYPE html>
<meta charset="utf-8"/>
<meta name="color-scheme" content="light dark"/>
<meta http-equiv="refresh" content="0;url=about:blank"/>
EOF

# Match bindings by stable ids rather than surrounding line numbers, so this
# works on both upstream Firefox and an archive previously patched by us.
for key_id in focusURLBar2 goBackKb goForwardKb; do
  key_count=$(grep -c "id=\"$key_id\"" "$browser_xhtml" || true)
  if [ "$key_count" -ne 1 ]; then
    echo "Expected one $key_id binding in browser.xhtml; found $key_count." >&2
    exit 1
  fi
done

perl -0pi -e '
  s{<key\b(?=[^>]*\bid="focusURLBar2")[^>]*/>}{<key id="focusURLBar2" data-l10n-id="location-open-shortcut-alt" command="Browser:OpenLocation"\n         modifiers="alt" reserved="true"/>}g;
  s{<key\b(?=[^>]*\bid="goBackKb")[^>]*/>}{<key id="goBackKb" key="a" command="Browser:Back" modifiers="alt" reserved="true"/>}g;
  s{<key\b(?=[^>]*\bid="goForwardKb")[^>]*/>}{<key id="goForwardKb" key="s" command="Browser:Forward" modifiers="alt" reserved="true"/>}g;
  s{^[ \t]*<key\b(?=[^>]*\bid="(?:goNextTab|goPrevTab)")[^>]*/>\n?}{}gm;
  s{(^[ \t]*<key\b(?=[^>]*\bid="goForwardKb")[^>]*/>)}{$1\n    <key id="goNextTab" key="e" command="Browser:NextTab" modifiers="accel"/>\n    <key id="goPrevTab" key="d" command="Browser:PrevTab" modifiers="accel"/>}m;
' "$browser_xhtml"

for expected in \
  'id="focusURLBar2"[^>]*modifiers="alt" reserved="true"' \
  'id="goBackKb" key="a"[^>]*modifiers="alt" reserved="true"' \
  'id="goForwardKb" key="s"[^>]*modifiers="alt" reserved="true"' \
  'id="goNextTab" key="e"' \
  'id="goPrevTab" key="d"'; do
  if ! EXPECTED_BINDING="$expected" perl -0ne 'exit(/$ENV{EXPECTED_BINDING}/s ? 0 : 1)' "$browser_xhtml"; then
    echo "Failed to produce expected browser.xhtml binding: $expected" >&2
    exit 1
  fi
done

(cd "$tempdir/extract" && zip -qr9XD "$tempdir/omni.ja" .)
unzip -tq "$tempdir/omni.ja" >/dev/null

if [ -w "$firefox_archive" ]; then
  if $backup_pristine; then
    cp "$firefox_archive" "${firefox_archive}.orig"
  fi
  cp "$tempdir/omni.ja" "$firefox_archive"
else
  if $backup_pristine; then
    sudo cp "$firefox_archive" "${firefox_archive}.orig"
  fi
  sudo install -m 0644 "$tempdir/omni.ja" "$firefox_archive"
fi
if [ -d "$firefox_cache" ]; then
  find "$firefox_cache" -type d -name startupCache -exec rm -rf {} +
fi
