#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "Use: $0 /path/to/wallpaper"
	exit 1
fi

WALLPAPER="$1"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="$RUNTIME_DIR/vibeshell-mpvpaper.lock"
SOCKET_PATH="$RUNTIME_DIR/mpvpaper-ipc.sock"

# Try sending a command to check if it's responsive
if [ -S "$SOCKET_PATH" ] && echo '{"command": ["get_property", "path"]}' | nc -w 1 -U "$SOCKET_PATH" >/dev/null 2>&1; then
	echo "DEBUG: mpvpaper is running. Loading new file via IPC."
	echo "{\"command\": [\"loadfile\", \"$WALLPAPER\"]}" | nc -w 1 -U "$SOCKET_PATH" >/dev/null 2>&1
	exit 0
fi

exec 9>"$LOCK_FILE"
flock -x 9

# Kill hyprpaper to save memory when running live wallpapers
pkill -x hyprpaper 2>/dev/null || true

# Nix wraps mpvpaper, so the real process name is not plain "mpvpaper".
# Match the command path instead and serialize restarts so old players cannot pile up.
rm -f "$SOCKET_PATH"
pkill -f '/bin/mpvpaper( |$)' 2>/dev/null || true

for _ in $(seq 1 20); do
	if ! pgrep -f '/bin/mpvpaper( |$)' >/dev/null 2>&1; then
		break
	fi
	sleep 0.05
done

# Close the lock fd in the detached player. If mpvpaper inherits it, later
# restarts block forever on flock after a Vibeshell reload.
nohup mpvpaper -o "input-ipc-server=$SOCKET_PATH no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 load-scripts=no demuxer-max-bytes=10M demuxer-max-back-bytes=2M vd-lavc-threads=1" ALL "$WALLPAPER" >/dev/null 2>&1 9>&- &
