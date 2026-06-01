#!/usr/bin/env bash

set -u

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
mkdir -p "$state_dir"
log_file="$state_dir/copyq.log"

if [ -z "${DISPLAY:-}" ]; then
    echo "x11-clipboard: DISPLAY is not set" >&2
    exit 1
fi

if ! command -v copyq >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Qtile" "Clipboard" "CopyQ is not installed yet. Rebuild the system first." >/dev/null 2>&1 || true
    fi
    exit 127
fi

start_copyq() {
    if ! copyq count >/dev/null 2>&1; then
        copyq --start-server >/dev/null 2>>"$log_file" || true
        for _ in 1 2 3 4 5; do
            sleep 0.1
            copyq count >/dev/null 2>&1 && return 0
        done
    fi
}

start_copyq

case "${1:-toggle}" in
    show)
        exec copyq show
        ;;
    paste)
        exec copyq paste
        ;;
    status)
        copyq count
        ;;
    toggle | *)
        exec copyq toggle
        ;;
esac
