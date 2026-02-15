#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "Use: $0 /path/to/wallpaper"
	exit 1
fi

WALLPAPER="$1"

pkill -x "mpvpaper" 2>/dev/null

nohup mpvpaper -o "no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 load-scripts=no" ALL "$WALLPAPER" >/dev/null 2>&1 &
