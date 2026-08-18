#!/usr/bin/env bash

set -euo pipefail

pactl_bin="${PACTL_BIN:-pactl}"
xm6_sink_prefix="${XM6_SINK_PREFIX:-bluez_output.58_18_62_26_39_3E.}"

xm6_sink_id() {
	"$pactl_bin" list short sinks | awk -v prefix="$xm6_sink_prefix" '
		index($2, prefix) == 1 {
			print $1
			exit
		}
	'
}

mute_all_sinks() {
	local sink_id
	local sink_count=0

	while IFS=$'\t' read -r sink_id _; do
		[ -n "$sink_id" ] || continue
		"$pactl_bin" set-sink-mute "$sink_id" 1
		sink_count=$((sink_count + 1))
	done < <("$pactl_bin" list short sinks)

	printf 'XM6 disconnected; muted %d audio output(s).\n' "$sink_count"
}

connected=false
if [ -n "$(xm6_sink_id)" ]; then
	connected=true
fi

while IFS= read -r _; do
	sink_id="$(xm6_sink_id)"
	if [ -n "$sink_id" ] && [ "$connected" = false ]; then
		"$pactl_bin" set-sink-mute "$sink_id" 0
		connected=true
		printf 'XM6 connected; unmuted the headphones.\n'
	elif [ -z "$sink_id" ] && [ "$connected" = true ]; then
		# Profile changes briefly remove and recreate Bluetooth sinks. Avoid
		# muting other outputs unless the XM6 remains absent.
		sleep 0.25
		if [ -z "$(xm6_sink_id)" ]; then
			mute_all_sinks
			connected=false
		fi
	fi
done < <("$pactl_bin" subscribe)
