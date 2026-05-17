#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "Use: $0 /path/to/wallpaper"
	exit 1
fi

WALLPAPER="$1"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="$RUNTIME_DIR/vibeshell-mpvpaper.lock"

exec 9>"$LOCK_FILE"
flock -x 9

# Nix wraps mpvpaper, so the real process name is not plain "mpvpaper".
# Match the command path instead and serialize restarts so old players cannot pile up.
pkill -f '/bin/mpvpaper( |$)' 2>/dev/null || true

for _ in $(seq 1 20); do
	if ! pgrep -f '/bin/mpvpaper( |$)' >/dev/null 2>&1; then
		break
	fi
	sleep 0.05
done

nohup mpvpaper -o "no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 load-scripts=no" ALL "$WALLPAPER" >/dev/null 2>&1 &
