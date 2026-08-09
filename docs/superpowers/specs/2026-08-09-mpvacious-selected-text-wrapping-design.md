# mpvacious selected-text wrapping

## Goal

Keep the complete selected subtitle text visible in mpvacious's right-hand OSD
pane instead of letting long lines extend past the window.

## Design

- Keep `menu_max_shown_line_length` as the total safety cap. Ordinary menu rows
  retain their current truncation behavior.
- Wrap only the primary and secondary subtitle text shown by
  `menu:print_selection`.
- Insert ASS `\N` line breaks after at most 25 UTF-8 characters. This matches
  the existing 640-pixel-wide pane and 24-pixel CJK font without introducing a
  new user option.
- Preserve shorter lines and existing line boundaries.

## Testing

Add focused helper tests for short text, Japanese text wider than 25
characters, and existing newlines. Run the complete mpvacious Lua test suite,
then copy the tested fork into the dotfiles-managed mpv scripts directory.
