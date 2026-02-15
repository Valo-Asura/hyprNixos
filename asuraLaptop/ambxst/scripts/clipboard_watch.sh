#!/usr/bin/env bash
# Clipboard watcher that triggers checks on clipboard changes
# Usage: clipboard_watch.sh <check_script> <db_path> <insert_script> <data_dir>

CHECK_SCRIPT="$1"
DB_PATH="$2"
INSERT_SCRIPT="$3"
DATA_DIR="$4"

# Function to check clipboard
check_clipboard() {
    if "$CHECK_SCRIPT" "$DB_PATH" "$INSERT_SCRIPT" "$DATA_DIR" 2>&1; then
        echo "REFRESH_LIST"
    fi
}

# Watch clipboard and check on every change
wl-paste --watch sh -c "echo 'CLIPBOARD_CHANGE'" | while IFS= read -r line; do
    if [ "$line" = "CLIPBOARD_CHANGE" ]; then
        check_clipboard
    fi
done
