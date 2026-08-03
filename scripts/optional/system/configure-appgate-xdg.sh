#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
launcher=/usr/bin/appgate
vendor=/usr/bin/appgate.vendor
true_name="$(dpkg-divert --truename "$launcher")"

case "$true_name" in
"$launcher")
	[ -x "$launcher" ] || {
		echo "Appgate is not installed at $launcher." >&2
		exit 1
	}
	sudo dpkg-divert --quiet --local --add --rename \
		--divert "$vendor" "$launcher"
	;;
"$vendor") ;;
*)
	echo "$launcher is already diverted to $true_name." >&2
	exit 1
	;;
esac

sudo install -m 755 "$repo/bin/appgate" "$launcher"
