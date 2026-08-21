#!/usr/bin/env bash

set -euo pipefail

APPGATE_VERSION="6.5.3+41284+release"
APPGATE_SHA256="3320b6f1c3933bd129bc7be5356b5d3516eecb0974b810fc1b9f9c0020733116"
APPGATE_DEB_URL="https://bin.appgate-sdp.com/6.5/client/appgate-sdp_6.5.3_amd64.deb"

architecture="${DEB_ARCHITECTURE:-$(dpkg --print-architecture)}"
if [ "$architecture" != amd64 ]; then
	printf 'Unsupported architecture for the pinned Appgate package: %s\n' \
		"$architecture" >&2
	exit 1
fi

installed_version="$(dpkg-query -W -f='${Version}' appgate 2>/dev/null || true)"
if [ "$installed_version" = "$APPGATE_VERSION" ]; then
	echo "Appgate $installed_version already installed."
	exit 0
fi

if [ -n "$installed_version" ]; then
	printf 'Appgate %s is installed; expected %s. Refusing to replace a potentially active VPN client.\n' \
		"$installed_version" "$APPGATE_VERSION" >&2
	exit 1
fi

staging_dir="$(mktemp -d)"
cleanup() {
	rm -rf "$staging_dir"
}
trap cleanup EXIT

deb="$staging_dir/appgate-sdp_6.5.3_amd64.deb"
curl --fail --silent --show-error --location \
	--output "$deb" "$APPGATE_DEB_URL"
printf '%s  %s\n' "$APPGATE_SHA256" "$deb" | sha256sum --check --status

package="$(dpkg-deb -f "$deb" Package)"
package_version="$(dpkg-deb -f "$deb" Version)"
package_architecture="$(dpkg-deb -f "$deb" Architecture)"
if [ "$package" != appgate ] ||
	[ "$package_version" != "$APPGATE_VERSION" ] ||
	[ "$package_architecture" != amd64 ]; then
	printf 'Unexpected Appgate package metadata: %s %s %s\n' \
		"$package" "$package_version" "$package_architecture" >&2
	exit 1
fi

sudo apt-get install -y "$deb"

installed_version="$(dpkg-query -W -f='${Version}' appgate)"
if [ "$installed_version" != "$APPGATE_VERSION" ]; then
	printf 'Unexpected Appgate version after installation: %s\n' \
		"$installed_version" >&2
	exit 1
fi

echo "Installed Appgate $APPGATE_VERSION."
