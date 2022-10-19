#!/bin/bash

cd ~/.mozilla/firefox/
if [[ $(grep '\[Profile[^0]\]' profiles.ini) ]]
then PROFPATH=$(grep -E '^\[Profile|^Path|^Default' profiles.ini | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
else PROFPATH=$(grep 'Path=' profiles.ini | sed 's/^Path=//')
fi

echo $PROFPATH
cd $PROFPATH

cat  <<'EOF' > user.js
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("webchannel.allowObject.urlWhitelist", "https://content.cdn.mozilla.net https://support.mozilla.org https://install.mozilla.org https://accounts.firefox.com");
EOF

mkdir -p chrome && cd chrome

cat  <<'EOF' > userContent.css
@-moz-document regexp("^moz-extension://.*search.html.*$") {
  .content { 
    background-color: #777; 
  }
}
EOF