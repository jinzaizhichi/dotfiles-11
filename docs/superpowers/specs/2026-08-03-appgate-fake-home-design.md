# Appgate Fake Home Design

## Goal

Keep Appgate's home-relative state out of the real home directory without
symlinking `~/.appgate`.

## Design

Keep the `bin/appgate` wrapper, which sets `HOME` to
`$XDG_DATA_HOME/appgate/home` and forwards every argument unchanged. Use
Debian's `dpkg-divert` to preserve the package-owned launcher as
`/usr/bin/appgate.vendor`, then install the same wrapper at
`/usr/bin/appgate`. This covers desktop, protocol-handler, PATH, and absolute
`/usr/bin/appgate` launches while allowing package upgrades to retain the
diversion.

Provide an explicit optional system configuration script because Appgate is
not part of the default bootstrap. It must not stop, restart, disconnect, or
signal a running Appgate process. Remove a regenerated `~/.appgate` only after
verifying no running Appgate process has files open there.

Move existing state into the fake home when needed and rewrite absolute paths
stored in `.ui.audit.log` metadata.
The system driver remains untouched because it already logs to
`/var/log/appgate/driver.log`.

## Verification

Run the wrapper against a harmless fake executable and verify the fake home,
argument forwarding, vendor fallback, and directory creation. Verify the
system launcher is diverted without changing the running Appgate PID, then
confirm the real home no longer contains `.appgate`.
