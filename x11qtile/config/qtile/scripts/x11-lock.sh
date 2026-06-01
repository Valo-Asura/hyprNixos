#!/usr/bin/env bash

set -u

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

if [ -z "${DISPLAY:-}" ]; then
    echo "x11-lock: DISPLAY is not set; refusing to start an X11 locker" >&2
    exit 1
fi

image="/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
if [ ! -r "$image" ]; then
    image="$HOME/.config/x11qtile/wallpapers/fog_forest_2.png"
fi

resume_dunst=0
if command -v dunstctl >/dev/null 2>&1; then
    was_paused="$(dunstctl is-paused 2>/dev/null || echo false)"
    if [ "$was_paused" != "true" ]; then
        dunstctl set-paused true >/dev/null 2>&1 || true
        resume_dunst=1
    fi
fi

cleanup() {
    if [ "$resume_dunst" -eq 1 ] && command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused false >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

if command -v xset >/dev/null 2>&1; then
    xset s activate >/dev/null 2>&1 || true
fi

if command -v i3lock-color >/dev/null 2>&1; then
    i3lock-color \
        --nofork \
        --ignore-empty-password \
        --show-failed-attempts \
        --clock \
        --indicator \
        --fill \
        --image "$image" \
        --radius 95 \
        --ring-width 7 \
        --inside-color=1f1d2ecc \
        --ring-color=caa9e0ff \
        --line-color=00000000 \
        --separator-color=00000000 \
        --keyhl-color=91b1f0ff \
        --bshl-color=ff6e6eff \
        --insidever-color=1f1d2ecc \
        --ringver-color=91b1f0ff \
        --insidewrong-color=1f1d2ecc \
        --ringwrong-color=ff6e6eff \
        --time-color=caa9e0ff \
        --date-color=caa9e0ff \
        --verif-color=caa9e0ff \
        --wrong-color=ff6e6eff \
        --layout-color=caa9e0ff \
        --greeter-text="Asura" \
        --greeter-color=caa9e0ff \
        --no-modkey-text
    exit "$?"
fi

i3lock -n -e -i "$image"
