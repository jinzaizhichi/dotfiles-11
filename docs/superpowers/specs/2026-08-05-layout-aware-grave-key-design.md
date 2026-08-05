# Layout-Aware Grave Key Design

## Goal

Keep `~` unshifted and backtick shifted in the US layout while preserving standard Russian `ё` and `Ё` behavior.

## Design

- Kanata passes the grave key through unchanged and continues to own sticky Shift and the Space symbol layer.
- A standalone `tilde-first` XKB symbols file includes the standard US layout and overrides only `<TLDE>`.
- The shared keyboard configuration selects `tilde-first,ru`; Russian remains the unmodified system layout.
- The desktop bootstrap installs the standalone symbols file before applying the keyboard configuration. It does not edit packaged XKB files.
- Tests cover the installed symbols file, Cinnamon/X11 arguments, KDE layout values, and Kanata passthrough.

## Scope

This supports Ubuntu 24.04 Cinnamon/X11 and Kubuntu 26.04 Plasma/Wayland. Windows and macOS require equivalent native keyboard-layout definitions; the portable Kanata behaviors remain usable there.
