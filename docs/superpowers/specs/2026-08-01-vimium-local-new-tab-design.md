# Local New Tab Design

## Goal

Keep Vimium current while preserving the private background page for both Firefox's `Ctrl+T` and Vimium's `t` command.

## Design

- Store the page and WebP separately under `configs/xdg/new-tab/`.
- Serve that directory only on `127.0.0.1:8766` using Python's standard-library HTTP server and a systemd user service.
- Configure New Tab Override's **Custom URL** as `http://127.0.0.1:8766/blank.html` and make it focus the website.
- Configure Vimium's new-tab destination as **Browser's default new tab page**. Its `t` command then creates an ordinary new tab, which New Tab Override handles just like `Ctrl+T`.
- Preserve the active appearance: full height, zero margin, no repeat, cover sizing, and right-center positioning.

## Constraints

Firefox rejects `file://` URLs supplied to the WebExtensions tab-creation API, and Vimium cannot inject into New Tab Override's `moz-extension://` local-file page. Do not point Vimium directly at the file, patch either extension, expose the service beyond loopback, or mutate Firefox's extension-storage databases.

## Fresh-machine behavior

The bootstrap links the tracked files to `$XDG_CONFIG_HOME/new-tab/`. The optional Firefox configuration script links and enables the user service. Firefox requires a one-time New Tab Override configuration.

## Verification

- The bootstrap test verifies the XDG link, page assets, unit, and service-enabling command.
- Render the tracked page in Firefox and verify the background fills the viewport at right center.
- Confirm that the service listens only on `127.0.0.1` and that `Ctrl+T` plus Vimium's `t` open the loopback page with Vimium active.
