# Desktop keyboard configuration

## Design

Replace `configure-cinnamon.sh` with one `configure-desktop.sh` entry point.
`configs/system/keyboard` is the repository's single source of truth. The script
first installs it as `/etc/default/keyboard`, because Ubuntu does
not support `localectl set-x11-keymap` and Cinnamon's stored settings do not
override the `us`-only system map at login. It then selects the active desktop from `XDG_CURRENT_DESKTOP`,
resets Cinnamon's layout overrides, tells IBus to preserve the system XKB
layout, and derives KDE Plasma's `kxkbrc` values from the same file using
`kwriteconfig6` or `kwriteconfig5`, and leaves desktop-specific settings alone
for unknown desktops.

Both implementations configure US and Russian layouts, Alt+Shift switching,
a 220 ms repeat delay, and 40 repeats per second. Plasma stores layouts in
`kxkbrc` and repeat settings in `kcminputrc`; configuration takes effect on
the next Plasma login. The bootstrap does not install KDE or link whole KDE
configuration files.

After applying the persistent setting, load the same map into the current X11
session with `setxkbmap` when a display is available. This avoids requiring a
logout and is not used as a persistence mechanism.

Tests cover the system setting, Cinnamon, KDE, and an unknown desktop.
