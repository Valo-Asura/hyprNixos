#!/usr/bin/env bash

# Sleep Monitor - Executes commands before and after sleep
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/Ambxst/config/system.json"

get_cmd() {
    local type=$1
    if [ -f "$CONFIG_FILE" ]; then
        if [ "$type" == "before" ]; then
            jq -r '.idle.general.before_sleep_cmd // "hyprlock"' "$CONFIG_FILE"
        else
            jq -r '.idle.general.after_sleep_cmd // "ambxst screen on"' "$CONFIG_FILE"
        fi
    else
        if [ "$type" == "before" ]; then
            echo "hyprlock"
        else
            echo "ambxst screen on"
        fi
    fi
}

# Monitor logind's PrepareForSleep signal
# Signal signature: b (boolean) - true = sleeping, false = waking
dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" | \
while read -r line; do
  # Look for the member line to confirm signal
  if echo "$line" | grep -q "member=PrepareForSleep"; then
    # Read the next line which contains the boolean argument
    read -r arg_line
    if echo "$arg_line" | grep -q "true"; then
      # Going to sleep
      CMD=$(get_cmd "before")
      if [ ! -z "$CMD" ]; then
        eval "$CMD" &
      fi
    elif echo "$arg_line" | grep -q "false"; then
      # Waking up
      CMD=$(get_cmd "after")
      if [ ! -z "$CMD" ]; then
        eval "$CMD" &
      fi
    fi
  fi
done
