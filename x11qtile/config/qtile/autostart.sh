#!/usr/bin/env bash

set -u

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

# Set wallpaper
wallpaper="$HOME/.config/x11qtile/wallpapers/Aesthetic2.png"
if command -v feh >/dev/null 2>&1 && [ -r "$wallpaper" ]; then
    feh --bg-fill "$wallpaper"
elif command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#282738"
fi

# Start picom
if command -v picom >/dev/null 2>&1 && ! pgrep -x picom >/dev/null 2>&1; then
    if [ -f "$HOME/.config/x11qtile/picom.conf" ]; then
        picom --config "$HOME/.config/x11qtile/picom.conf" &
    else
        picom &
    fi
fi

# Start other helper daemons
if command -v dunst >/dev/null 2>&1 && ! pgrep -x dunst >/dev/null 2>&1; then
    dunst &
fi

if command -v nm-applet >/dev/null 2>&1 && ! pgrep -x nm-applet >/dev/null 2>&1; then
    nm-applet --indicator &
fi
