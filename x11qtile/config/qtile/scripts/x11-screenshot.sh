#!/usr/bin/env bash

set -euo pipefail

screenshot_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
tmp_file="$(mktemp --suffix=.png)"

cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot" "$1" >/dev/null 2>&1 || true
    fi
}

copy_image() {
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
    local clipboard_file="$state_dir/clipboard-screenshot.png"
    mkdir -p "$state_dir"
    cp "$1" "$clipboard_file"
    pkill -f "xclip .*clipboard-screenshot.png" >/dev/null 2>&1 || true
    xclip -selection clipboard -target image/png -i "$clipboard_file" >/dev/null 2>&1 &
}

save_image() {
    mkdir -p "$screenshot_dir"
    local output="$screenshot_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    cp "$1" "$output"
    printf '%s\n' "$output"
}

capture() {
    local mode="$1"
    case "$mode" in
        area)
            maim -s "$tmp_file"
            ;;
        full)
            maim "$tmp_file"
            ;;
        window)
            local window_id
            window_id="$(xdotool selectwindow)"
            maim -i "$window_id" "$tmp_file"
            ;;
        *)
            printf 'unknown capture mode: %s\n' "$mode" >&2
            exit 2
            ;;
    esac
}

capture_copy() {
    capture "$1"
    copy_image "$tmp_file"
    notify "Copied PNG image to clipboard."
}

capture_save_copy() {
    capture "$1"
    local output
    output="$(save_image "$tmp_file")"
    copy_image "$tmp_file"
    notify "Saved and copied: $output"
}

menu() {
    local choice
    choice="$(
        printf '%s\n' \
            "Area -> Clipboard" \
            "Area -> File + Clipboard" \
            "Fullscreen -> Clipboard" \
            "Fullscreen -> File + Clipboard" \
            "Window -> Clipboard" \
            "Window -> File + Clipboard" |
            rofi -dmenu -i -p "Screenshot"
    )"

    case "$choice" in
        "Area -> Clipboard") capture_copy area ;;
        "Area -> File + Clipboard") capture_save_copy area ;;
        "Fullscreen -> Clipboard") capture_copy full ;;
        "Fullscreen -> File + Clipboard") capture_save_copy full ;;
        "Window -> Clipboard") capture_copy window ;;
        "Window -> File + Clipboard") capture_save_copy window ;;
        "") exit 0 ;;
        *) exit 1 ;;
    esac
}

case "${1:-menu}" in
    area-copy) capture_copy area ;;
    area-save-copy) capture_save_copy area ;;
    full-copy) capture_copy full ;;
    full-save-copy) capture_save_copy full ;;
    window-copy) capture_copy window ;;
    window-save-copy) capture_save_copy window ;;
    menu) menu ;;
    *)
        printf 'usage: %s [menu|area-copy|area-save-copy|full-copy|full-save-copy|window-copy|window-save-copy]\n' "$0" >&2
        exit 2
        ;;
esac
