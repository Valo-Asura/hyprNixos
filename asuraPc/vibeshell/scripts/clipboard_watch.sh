#!/usr/bin/env bash
# Clipboard watcher that triggers checks on clipboard changes
# Usage: clipboard_watch.sh <check_script> <db_path> <insert_script> <data_dir>

CHECK_SCRIPT="$1"
DB_PATH="$2"
INSERT_SCRIPT="$3"
DATA_DIR="$4"

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/vibeshell-clipboard-watch.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 75

# Keep wl-paste in the foreground so Quickshell tracks one long-lived watcher.
exec wl-paste --watch bash -c '
    check_script="$1"
    db_path="$2"
    insert_script="$3"
    data_dir="$4"

    if "$check_script" "$db_path" "$insert_script" "$data_dir" >/dev/null 2>&1; then
        printf "%s\n" "REFRESH_LIST"
    fi
' _ "$CHECK_SCRIPT" "$DB_PATH" "$INSERT_SCRIPT" "$DATA_DIR"
