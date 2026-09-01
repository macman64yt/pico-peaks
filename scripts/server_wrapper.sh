#!/bin/bash
# Pico Peaks dedicated server launcher helper.
# Usage: server_wrapper.sh [--port N] [--max-players N] [--seed N] [--ram-mb N] [--name "Name"]
PORT=25565
MAX=8
SEED=2024
RAM=2048
NAME="Pico Peaks Server"
while [ $# -gt 0 ]; do
	case "$1" in
		--port) PORT="$2"; shift 2;;
		--max-players) MAX="$2"; shift 2;;
		--seed) SEED="$2"; shift 2;;
		--ram-mb) RAM="$2"; shift 2;;
		--name) NAME="$2"; shift 2;;
		*) shift;;
	esac
done

PID_FILE=/tmp/opencode/server.pid
LOG_FILE=/tmp/opencode/server.log

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$BIN_DIR/pico-peaks-1.0.0"
if [ ! -x "$BIN" ]; then
	# Dev layout fallback: wrapper lives in <project>/scripts, binary in <project>/build
	BIN="$BIN_DIR/../build/pico-peaks-1.0.0"
fi
if [ ! -x "$BIN" ]; then
	echo "ERROR: server binary not found (looked next to wrapper and in build/): $BIN" >&2
	exit 1
fi

if [ -f "$PID_FILE" ]; then
	OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
	if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
		kill "$OLD_PID" 2>/dev/null
		for _ in $(seq 1 10); do
			kill -0 "$OLD_PID" 2>/dev/null || break
			sleep 1
		done
		if kill -0 "$OLD_PID" 2>/dev/null; then
			kill -9 "$OLD_PID" 2>/dev/null
			sleep 1
		fi
	fi
fi

mkdir -p /tmp/opencode
nohup setsid "$BIN" --headless -- \
	--server --port "$PORT" --max-players "$MAX" --seed "$SEED" --ram-mb "$RAM" \
	--server-name "$NAME" </dev/null >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
