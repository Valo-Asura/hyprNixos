#!/usr/bin/env bash

set -u

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
enabled_file="$state_dir/caffeine.enabled"
pid_file="$state_dir/caffeine.pid"
mkdir -p "$state_dir"

notify() {
    if [ "${X11QTILE_QUIET:-0}" != 1 ] && command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Qtile" "Caffeine mode" "$1" >/dev/null 2>&1 || true
    fi
}

stop_inhibitor() {
    if [ -r "$pid_file" ]; then
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    fi
    rm -f "$pid_file"
}

start_inhibitor() {
    if [ -r "$pid_file" ]; then
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return
        fi
    fi

    if command -v systemd-inhibit >/dev/null 2>&1; then
        systemd-inhibit \
            --what=idle:sleep:handle-lid-switch \
            --who=x11qtile \
            --why="Qtile caffeine mode" \
            sleep infinity &
        echo "$!" > "$pid_file"
    fi
}

enable() {
    touch "$enabled_file"
    if [ -n "${DISPLAY:-}" ] && command -v xset >/dev/null 2>&1; then
        xset s off -dpms s noblank >/dev/null 2>&1 || true
    fi
    start_inhibitor
    notify "Idle lock and sleep are inhibited."
}

disable() {
    rm -f "$enabled_file"
    if [ -n "${DISPLAY:-}" ] && command -v xset >/dev/null 2>&1; then
        xset s on +dpms >/dev/null 2>&1 || true
    fi
    stop_inhibitor
    notify "Idle lock and sleep are back to normal."
}

case "${1:-toggle}" in
    enable)
        enable
        ;;
    disable)
        disable
        ;;
    apply)
        if [ -e "$enabled_file" ]; then
            X11QTILE_QUIET=1 enable
        else
            X11QTILE_QUIET=1 disable
        fi
        ;;
    status)
        if [ -e "$enabled_file" ]; then
            echo "on"
        else
            echo "off"
        fi
        ;;
    toggle | *)
        if [ -e "$enabled_file" ]; then
            disable
        else
            enable
        fi
        ;;
esac
