#!/usr/bin/env bash

set -u

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

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

# Auto-detect connected display outputs and set refresh rate to 165Hz
if command -v xrandr >/dev/null 2>&1; then
    connected_output=$(xrandr | grep " connected " | awk '{print $1}' | head -n 1)
    if [ -n "$connected_output" ]; then
        xrandr --output "$connected_output" --mode 1920x1080 --rate 165.00 || \
        xrandr --output "$connected_output" --mode 1920x1080 --rate 165 || \
        xrandr --output "$connected_output" --auto
    fi
fi

# Some Xorg sessions start with an invisible root cursor.
if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -cursor_name left_ptr
fi

# Set wallpaper
wallpaper="$HOME/.config/x11qtile/wallpapers/fog_forest_2.png"
if command -v feh >/dev/null 2>&1 && [ -r "$wallpaper" ]; then
    feh --bg-fill "$wallpaper"
elif command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#282738"
fi

# Start picom compositor by default
if [ "${X11QTILE_ENABLE_PICOM:-1}" = "1" ] \
    && command -v picom >/dev/null 2>&1 \
    && ! pgrep -x picom >/dev/null 2>&1; then
    picom_config="$HOME/.config/x11qtile/picom.conf"
    if [ -n "${X11QTILE_CONFIG_DIR:-}" ]; then
        sibling_config="$(dirname "$X11QTILE_CONFIG_DIR")/picom.conf"
        if [ -r "$sibling_config" ]; then
            picom_config="$sibling_config"
        fi
    fi

    if [ -r "$picom_config" ]; then
        picom --config "$picom_config" >>"$state_dir/picom.log" 2>&1 &
    else
        picom >>"$state_dir/picom.log" 2>&1 &
    fi
fi

# Start other helper daemons
if command -v dunst >/dev/null 2>&1 && ! pgrep -x dunst >/dev/null 2>&1; then
    if ! command -v busctl >/dev/null 2>&1 || ! busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
        dunst >>"$state_dir/dunst.log" 2>&1 &
    fi
fi

if [ "${X11QTILE_ENABLE_NM_APPLET:-0}" = "1" ] \
    && command -v nm-applet >/dev/null 2>&1 \
    && ! pgrep -x nm-applet >/dev/null 2>&1; then
    nm-applet --indicator >>"$state_dir/nm-applet.log" 2>&1 &
fi

if [ "${X11QTILE_ENABLE_COPYQ:-0}" = "1" ] && command -v copyq >/dev/null 2>&1; then
    QT_QPA_PLATFORM=xcb copyq --start-server >>"$state_dir/copyq.log" 2>&1 || true
fi

script_dir="$HOME/.config/x11qtile/qtile/scripts"
if [ -n "${X11QTILE_CONFIG_DIR:-}" ]; then
    script_dir="$X11QTILE_CONFIG_DIR/scripts"
fi

# Re-apply persistent session toggles without blocking Qtile startup.
if [ -r "$script_dir/caffeine-toggle.sh" ]; then
    X11QTILE_QUIET=1 bash "$script_dir/caffeine-toggle.sh" apply >>"$state_dir/caffeine.log" 2>&1 || true
fi

if [ -r "$script_dir/night-light-toggle.sh" ]; then
    X11QTILE_QUIET=1 bash "$script_dir/night-light-toggle.sh" apply >>"$state_dir/night-light.log" 2>&1 || true
fi

# Eww bar removed in favor of native Qtile bar

# Start background weather poll loop (updates every 30 mins, 100% non-blocking)
(
    # Initial sleep to let network connect
    sleep 5
    while true; do
        weather_data=$(curl -s "wttr.in/?format=%t,+%C" || echo "")
        if [ -n "$weather_data" ]; then
            echo "$weather_data" > "$state_dir/weather.txt"
        fi
        sleep 1800
    done
) &
