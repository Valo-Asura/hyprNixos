#!/usr/bin/env bash

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/Ambxst/config/system.json"

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ambxst-loginlock.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

get_lock_cmd() {
	if [ -f "$CONFIG_FILE" ]; then
		jq -r '.idle.general.lock_cmd // "ambxst-safe-lock"' "$CONFIG_FILE"
	else
		echo "ambxst-safe-lock"
	fi
}

dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Session',member='Lock'" |
	while read -r line; do
		if echo "$line" | grep -q "member=Lock"; then
			COMMAND=$(get_lock_cmd)
			if [ -n "$COMMAND" ]; then
				eval "$COMMAND" &
			fi
		fi
	done
