#!/usr/bin/env bash

set -u

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
mkdir -p "$state_dir"

# Make X11 input match the working Hyprland layout and ensure SUPER is mod4.
if command -v setxkbmap >/dev/null 2>&1; then
    setxkbmap -layout us -option caps:escape
fi

if command -v xmodmap >/dev/null 2>&1; then
    xmodmap -e "clear mod4" \
        -e "add mod4 = Super_L Super_R Hyper_L" >/dev/null 2>&1 || true
fi

# Some Xorg sessions start with an invisible root cursor.
if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -cursor_name left_ptr
fi

# Set wallpaper
wallpaper="$HOME/.config/x11qtile/wallpapers/Aesthetic2.png"
if command -v feh >/dev/null 2>&1 && [ -r "$wallpaper" ]; then
    feh --bg-fill "$wallpaper"
elif command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#282738"
fi

# Start picom
if command -v picom >/dev/null 2>&1 && ! pgrep -x picom >/dev/null 2>&1; then
    picom_config="$HOME/.config/x11qtile/picom.conf"
    if [ -n "${X11QTILE_CONFIG_DIR:-}" ]; then
        sibling_config="$(dirname "$X11QTILE_CONFIG_DIR")/picom.conf"
        if [ -r "$sibling_config" ]; then
            picom_config="$sibling_config"
        fi
    fi

    if [ -r "$picom_config" ]; then
        picom --backend xrender --config "$picom_config" >>"$state_dir/picom.log" 2>&1 &
    else
        picom --backend xrender >>"$state_dir/picom.log" 2>&1 &
    fi
fi

# Start other helper daemons
if command -v dunst >/dev/null 2>&1 && ! pgrep -x dunst >/dev/null 2>&1; then
    if ! command -v busctl >/dev/null 2>&1 || ! busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
        dunst >>"$state_dir/dunst.log" 2>&1 &
    fi
fi

if command -v nm-applet >/dev/null 2>&1 && ! pgrep -x nm-applet >/dev/null 2>&1; then
    nm-applet --indicator >>"$state_dir/nm-applet.log" 2>&1 &
fi
