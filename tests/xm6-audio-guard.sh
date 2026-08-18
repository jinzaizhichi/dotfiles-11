#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

state_file="$temp_dir/state"
mute_log="$temp_dir/mute.log"
query_log="$temp_dir/query.log"
printf 'connected\n' >"$state_file"

cat >"$temp_dir/pactl" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

case "$1 ${2:-} ${3:-}" in
"list short sinks")
	printf 'list\n' >>"$AUDIO_GUARD_TEST_QUERY_LOG"
	case "$(cat "$AUDIO_GUARD_TEST_STATE")" in
	connected)
		printf '20\tbluez_output.58_18_62_26_39_3E.1\tPipeWire\n'
		;;
	disconnected)
		printf '10\talsa_output.internal\tPipeWire\n'
		;;
	reconnected)
		printf '10\talsa_output.internal\tPipeWire\n'
		printf '21\tbluez_output.58_18_62_26_39_3E.1\tPipeWire\n'
		;;
	esac
	;;
"set-sink-mute "*)
	printf '%s %s\n' "$2" "$3" >>"$AUDIO_GUARD_TEST_LOG"
	;;
"subscribe "*)
	printf 'disconnected\n' >"$AUDIO_GUARD_TEST_STATE"
	printf "Event 'new' on client #99\n"
	printf "Event 'remove' on sink #20\n"
	sleep 0.35
	printf 'reconnected\n' >"$AUDIO_GUARD_TEST_STATE"
	printf "Event 'new' on sink #21\n"
	;;
*)
	printf 'Unexpected pactl arguments: %s\n' "$*" >&2
	exit 1
	;;
esac
EOF
chmod +x "$temp_dir/pactl"

AUDIO_GUARD_TEST_STATE="$state_file" \
    AUDIO_GUARD_TEST_LOG="$mute_log" \
    AUDIO_GUARD_TEST_QUERY_LOG="$query_log" \
    PACTL_BIN="$temp_dir/pactl" \
    "$repo/configs/xdg/xm6-audio-guard/watch.sh" >/dev/null

test "$(cat "$mute_log")" = $'10 1\n21 0'
test "$(wc -l <"$query_log")" -eq 5

repair_dir="$temp_dir/repair"
mkdir -p "$repair_dir"
repair_state="$repair_dir/state"
repair_log="$repair_dir/actions.log"
restart_marker="$repair_dir/restarted"
printf 'broken\n' >"$repair_state"

cat >"$repair_dir/pactl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1 ${2:-} ${3:-}" in
"list short sinks")
	printf '10\talsa_output.internal\tPipeWire\n'
	if [ "$(cat "$XM6_REPAIR_STATE")" = healthy ]; then
		printf '20\tbluez_output.58_18_62_26_39_3E.1\tPipeWire\n'
	fi
	;;
"set-default-sink "* | "set-sink-mute "*)
	printf 'pactl %s\n' "$*" >>"$XM6_REPAIR_LOG"
	;;
*)
	printf 'Unexpected pactl arguments: %s\n' "$*" >&2
	exit 1
	;;
esac
EOF

cat >"$repair_dir/bluetoothctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'bluetoothctl %s\n' "$*" >>"$XM6_REPAIR_LOG"
case "$1" in
list)
	printf 'Controller F8:54:F6:E8:47:CE test [default]\n'
	;;
disconnect) ;;
connect)
	if [ -f "$XM6_REPAIR_RESTARTED" ]; then
		printf 'healthy\n' >"$XM6_REPAIR_STATE"
	else
		exit 1
	fi
	;;
esac
EOF

cat >"$repair_dir/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'systemctl %s\n' "$*" >>"$XM6_REPAIR_LOG"
touch "$XM6_REPAIR_RESTARTED"
EOF

cat >"$repair_dir/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

cat >"$repair_dir/timeout" <<'EOF'
#!/usr/bin/env bash
shift
exec "$@"
EOF

cat >"$repair_dir/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$repair_dir"/*

BLUETOOTHCTL_BIN="$repair_dir/bluetoothctl" \
	PACTL_BIN="$repair_dir/pactl" \
	SLEEP_BIN="$repair_dir/sleep" \
	SUDO_BIN="$repair_dir/sudo" \
	SYSTEMCTL_BIN="$repair_dir/systemctl" \
	TIMEOUT_BIN="$repair_dir/timeout" \
	XM6_REPAIR_LOG="$repair_log" \
	XM6_REPAIR_RESTARTED="$restart_marker" \
	XM6_REPAIR_STATE="$repair_state" \
	"$repo/bin/fix-xm6-audio" >/dev/null

grep -Fqx 'systemctl restart bluetooth' "$repair_log"
grep -Fqx 'pactl set-default-sink bluez_output.58_18_62_26_39_3E.1' \
	"$repair_log"
grep -Fqx 'pactl set-sink-mute bluez_output.58_18_62_26_39_3E.1 0' \
	"$repair_log"
