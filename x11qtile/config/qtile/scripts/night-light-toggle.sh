#!/usr/bin/env bash

set -u

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-asura}/bin:$PATH"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
enabled_file="$state_dir/night-light.enabled"
temp_file="$state_dir/night-light.temp"
mkdir -p "$state_dir"

default_temp="${X11QTILE_NIGHT_TEMP:-4200}"

notify() {
    if [ "${X11QTILE_QUIET:-0}" != 1 ] && command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Qtile" "Night mode" "$1" >/dev/null 2>&1 || true
    fi
}

current_temp() {
    if [ -r "$temp_file" ]; then
        cat "$temp_file"
    else
        echo "$default_temp"
    fi
}

set_temp() {
    temp="$1"
    echo "$temp" > "$temp_file"

    if [ -z "${DISPLAY:-}" ]; then
        echo "night-light-toggle: DISPLAY is not set" >&2
        return 1
    fi

    if ! command -v redshift >/dev/null 2>&1; then
        echo "night-light-toggle: redshift is not installed" >&2
        return 1
    fi

    redshift -P -O "$temp" >/dev/null 2>&1
}

enable() {
    temp="$(current_temp)"
    set_temp "$temp" || return 1
    touch "$enabled_file"
    notify "Warm display enabled at ${temp}K."
}

disable() {
    rm -f "$enabled_file"
    if [ -n "${DISPLAY:-}" ] && command -v redshift >/dev/null 2>&1; then
        redshift -x >/dev/null 2>&1 || true
    fi
    notify "Display color reset."
}

cycle() {
    case "$(current_temp)" in
        4800) next=4200 ;;
        4200) next=3600 ;;
        *) next=4800 ;;
    esac

    echo "$next" > "$temp_file"
    touch "$enabled_file"
    set_temp "$next" || return 1
    notify "Warm display set to ${next}K."
}

case "${1:-toggle}" in
    enable)
        enable
        ;;
    disable)
        disable
        ;;
    cycle)
        cycle
        ;;
    apply)
        if [ -e "$enabled_file" ]; then
            X11QTILE_QUIET=1 enable
        fi
        ;;
    status)
        if [ -e "$enabled_file" ]; then
            printf 'on %sK\n' "$(current_temp)"
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
