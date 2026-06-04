#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "Use: $0 /path/to/wallpaper"
	exit 1
fi

WALLPAPER="$1"

# Kill mpvpaper if it is running to avoid overlays
pkill -f '/bin/mpvpaper( |$)' 2>/dev/null || true

# Start hyprpaper if not running
if ! pgrep -x hyprpaper >/dev/null; then
	# Force kill any zombie instances
	pkill -x hyprpaper 2>/dev/null || true
	nohup hyprpaper >/dev/null 2>&1 &
	
	# Wait for it to become responsive
	for _ in $(seq 1 30); do
		if pgrep -x hyprpaper >/dev/null; then
			sleep 0.1
			break
		fi
		sleep 0.1
	done
fi

# Set the wallpaper on all monitors
hyprctl hyprpaper wallpaper ",$WALLPAPER"

