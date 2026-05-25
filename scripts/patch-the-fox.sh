#!/bin/bash

set -e

tempdir=$(mktemp -d)
mkdir "$tempdir/extract"
cd "$tempdir/extract"
set +e
unzip /usr/lib/firefox/browser/omni.ja

cat << EOF > './chrome/browser/content/browser/blanktab.html'
<!DOCTYPE html>
<meta charset="utf-8"/>
<meta name="color-scheme" content="light dark"/>
<meta http-equiv="refresh" content="0;url=about:blank"/>
EOF

set -e
patch -p1 <<'EOF'
--- ./chrome/browser/content/browser/browser.xhtml	2010-01-01 00:00:00.000000000 +0100
+++ ./chrome/browser/content/browser/browser.xhtml.new	2020-03-22 19:32:36.283963602 +0100
@@ -247,11 +247,6 @@
     <key id="focusURLBar2" data-l10n-id="location-open-shortcut-alt" command="Browser:OpenLocation"
          modifiers="alt"/>
 
-    <key id="key_search" data-l10n-id="search-focus-shortcut" command="Tools:Search" modifiers="accel"/>
-    <key id="key_search2"
-         data-l10n-id="search-focus-shortcut-alt"
-         modifiers="accel"
-         command="Tools:Search"/>
     <key id="key_openDownloads"
          data-l10n-id="downloads-shortcut"
          modifiers="accel,shift"
@@ -288,8 +283,10 @@
 
     <key keycode="VK_BACK" command="cmd_handleBackspace" reserved="false"/>
     <key keycode="VK_BACK" command="cmd_handleShiftBackspace" modifiers="shift" reserved="false"/>
-    <key id="goBackKb"  keycode="VK_LEFT" command="Browser:Back" modifiers="alt"/>
-    <key id="goForwardKb"  keycode="VK_RIGHT" command="Browser:Forward" modifiers="alt"/>
+    <key id="goBackKb"  key="a" command="Browser:Back" modifiers="alt" reserved="true"/>
+    <key id="goForwardKb"  key="s" command="Browser:Forward" modifiers="alt" reserved="true"/>
+    <key id="goNextTab"  key="e" command="Browser:NextTab" modifiers="accel"/>
+    <key id="goPrevTab"  key="d" command="Browser:PrevTab" modifiers="accel"/>
     <key id="goBackKb2" data-l10n-id="nav-back-shortcut-alt" command="Browser:Back" modifiers="accel"/>
     <key id="goForwardKb2" data-l10n-id="nav-fwd-shortcut-alt" command="Browser:Forward" modifiers="accel"/>
     <key id="goHome" keycode="VK_HOME" modifiers="alt"/>
@@ -313,9 +310,7 @@
     <key id="key_viewSource" data-l10n-id="page-source-shortcut" command="View:PageSource" modifiers="accel"/>
     <key id="key_viewInfo" data-l10n-id="page-info-shortcut" command="View:PageInfo"   modifiers="accel"/>
     <key id="key_find" data-l10n-id="find-shortcut" command="cmd_find" modifiers="accel"/>
-    <key id="key_findAgain" data-l10n-id="search-find-again-shortcut" command="cmd_findAgain" modifiers="accel"/>
     <key id="key_findPrevious" data-l10n-id="search-find-again-shortcut" command="cmd_findPrevious" modifiers="accel,shift"/>
-    <key data-l10n-id="search-find-again-shortcut-alt" command="cmd_findAgain"/>
     <key data-l10n-id="search-find-again-shortcut-alt" command="cmd_findPrevious" modifiers="shift"/>
 
     <key id="addBookmarkAsKb" data-l10n-id="bookmark-this-page-shortcut" command="Browser:AddBookmarkAs" modifiers="accel"/>

EOF

zip -qr9XD ../omni.ja *
sudo bash -c "cp /usr/lib/firefox/browser/omni.ja /usr/lib/firefox/browser/omni.ja.orig ; cat $tempdir/omni.ja >/usr/lib/firefox/browser/omni.ja"
find ~/.cache/mozilla/firefox -type d -name startupCache | xargs rm -rf
cd /
rm -r "$tempdir"

