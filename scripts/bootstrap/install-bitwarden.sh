#!/usr/bin/env bash

set -euo pipefail

BITWARDEN_VERSION="2026.7.0"
BITWARDEN_SHA256="17523257c367f299a76d3670c7e329941fdaf14a4f9321cf38b347e35453ae64"
BITWARDEN_DEB_URL="https://github.com/bitwarden/clients/releases/download/desktop-v${BITWARDEN_VERSION}/Bitwarden-${BITWARDEN_VERSION}-amd64.deb"

architecture="${DEB_ARCHITECTURE:-$(dpkg --print-architecture)}"
if [ "$architecture" != amd64 ]; then
	printf 'Unsupported architecture for the pinned Bitwarden package: %s\n' \
		"$architecture" >&2
	exit 1
fi

installed_version="${BITWARDEN_INSTALLED_VERSION:-}"
if [ -z "$installed_version" ]; then
	installed_version="$(dpkg-query -W -f='${Version}' bitwarden 2>/dev/null || true)"
fi

if [ -n "$installed_version" ] &&
	dpkg --compare-versions "$installed_version" ge "$BITWARDEN_VERSION"; then
	echo "Bitwarden $installed_version already installed."
	exit 0
fi

staging_dir="$(mktemp -d)"
cleanup() {
	rm -rf "$staging_dir"
}
trap cleanup EXIT

deb="$staging_dir/Bitwarden-${BITWARDEN_VERSION}-amd64.deb"
curl --fail --silent --show-error --location \
	--output "$deb" "$BITWARDEN_DEB_URL"
printf '%s  %s\n' "$BITWARDEN_SHA256" "$deb" | sha256sum --check --status
sudo apt-get install -y "$deb"

installed_version="$(dpkg-query -W -f='${Version}' bitwarden)"
if [ "$installed_version" != "$BITWARDEN_VERSION" ]; then
	printf 'Unexpected Bitwarden version after installation: %s\n' \
		"$installed_version" >&2
	exit 1
fi

echo "Installed Bitwarden $BITWARDEN_VERSION."
