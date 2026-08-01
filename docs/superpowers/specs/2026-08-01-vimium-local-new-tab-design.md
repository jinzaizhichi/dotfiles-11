# Vimium Local New Tab Design

## Goal

Keep Vimium current while replacing its removed `pages/blank.html` with a private local page that preserves the existing background styling.

## Design

- Store the page at `xdg/vimium/blank.html` and its image at `xdg/vimium/background.webp`.
- Let the existing XDG linker expose them as `$XDG_CONFIG_HOME/vimium/blank.html` and `$XDG_CONFIG_HOME/vimium/background.webp`.
- Make the HTML self-contained except for the adjacent image. Preserve the active `userContent.css` behavior: full height, zero margin, no repeat, cover sizing, and right-center positioning.
- Configure Vimium's supported **Custom URL** setting to the resulting `file://` URL. Do not patch Vimium or mutate Firefox's extension-storage database.
- Remove the obsolete `pages/blank.html` CSS rule from the active Firefox profile after the local page is configured. Other `userContent.css` rules remain untouched.

## Fresh-machine behavior

The normal bootstrap links the tracked `xdg/vimium` directory. Firefox/Vimium setup documentation gives the generated local URL to enter once in Vimium; Firefox Sync may subsequently carry that setting between profiles using the same home path.

Vimium installation remains a user-confirmed Firefox action because Firefox does not permit an ordinary bootstrap script to silently install an AMO extension. No unsupported enterprise policy or direct SQLite editing is introduced.

## Verification

- The bootstrap test verifies the Vimium directory symlink and both page assets.
- A static check verifies that the page references `background.webp` and retains the required layout declarations.
- The current profile is checked manually after upgrading Vimium: `t` opens the local page, the image covers the viewport at right center, and normal Vimium commands work.
