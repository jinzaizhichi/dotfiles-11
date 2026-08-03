# Bob-managed Neovim nightly

Mise installs the latest Bob release alongside the repository's other
user-level command-line tools. Bob, in turn, installs and selects Neovim's
latest nightly build. Ubuntu's `neovim` package remains absent from the apt
package list.

The existing `install-mise.sh` flow installs Bob and then invokes Bob through
Mise so it does not depend on shell activation or shim lookup during
bootstrap. A failed Bob or Neovim installation fails the bootstrap rather
than leaving a silently incomplete editor setup.

Bootstrap tests use the existing fake Mise command and a fake Bob executable;
they verify that Bob is declared, installed, and asked to select `nightly`
without making network requests. Existing Neovim/AppImage files are not
deleted automatically, because replacement must be verified before removal.
