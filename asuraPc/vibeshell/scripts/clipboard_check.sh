#!/usr/bin/env bash
# Check clipboard and insert into database
# Usage: clipboard_check.sh <db_path> <script_path> <data_dir>

set -euo pipefail

DB_PATH="$1"
SCRIPT_PATH="$2"
DATA_DIR="$3"

mkdir -p "$(dirname "$DB_PATH")" "$DATA_DIR"

EVENT_LOCK="${XDG_RUNTIME_DIR:-/tmp}/vibeshell-clipboard-check.lock"
exec 8>"$EVENT_LOCK"
flock -n 8 || exit 0

MAX_TEXT_BYTES="${VIBESHELL_CLIPBOARD_MAX_TEXT_BYTES:-1048576}"
MAX_IMAGE_BYTES="${VIBESHELL_CLIPBOARD_MAX_IMAGE_BYTES:-26214400}"

# Check for files first (text/uri-list)
if FILE_CONTENT=$(wl-paste --type text/uri-list 2>/dev/null); then
    HASH=$(echo -n "$FILE_CONTENT" | tr -d '\r' | md5sum | cut -d' ' -f1)
    
    # Get file size if it's a local file
    FILE_SIZE=0
    FILE_PATH=$(echo -n "$FILE_CONTENT" | tr -d '\r' | sed 's|^file://||')
    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
    fi
    
    echo -n "$FILE_CONTENT" | tr -d '\r' | "$SCRIPT_PATH" "$DB_PATH" "$HASH" "text/uri-list" 0 "" "$FILE_SIZE"
    exit 0
fi

# Check for images
if IMAGE_MIME=$(wl-paste --list-types 2>/dev/null | grep '^image/' | head -1); then
    if [ -n "$IMAGE_MIME" ]; then
        # Determine file extension from MIME type
        case "$IMAGE_MIME" in
            image/png) EXT="png" ;;
            image/jpeg) EXT="jpg" ;;
            image/gif) EXT="gif" ;;
            image/webp) EXT="webp" ;;
            image/bmp) EXT="bmp" ;;
            image/svg+xml) EXT="svg" ;;
            *) EXT="img" ;;
        esac
        
        # Create filename with timestamp and extension
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="clipboard_${TIMESTAMP}.${EXT}"
        BINARY_PATH="$DATA_DIR/$FILENAME"
        
        wl-paste --type "$IMAGE_MIME" 2>/dev/null > "$BINARY_PATH"
        
        # Get image size
        IMAGE_SIZE=$(stat -c%s "$BINARY_PATH" 2>/dev/null || echo 0)
        if [ "$IMAGE_SIZE" -eq 0 ] || [ "$IMAGE_SIZE" -gt "$MAX_IMAGE_BYTES" ]; then
            rm -f "$BINARY_PATH"
            exit 0
        fi

        HASH=$(md5sum "$BINARY_PATH" | cut -d' ' -f1)
        
        echo -n '' | "$SCRIPT_PATH" "$DB_PATH" "$HASH" "$IMAGE_MIME" 1 "$BINARY_PATH" "$IMAGE_SIZE"
        exit 0
    fi
fi

check_text_type() {
    local mime="$1"
    local text_file
    text_file=$(mktemp)
    trap 'rm -f "$text_file"' RETURN

    if ! wl-paste --type "$mime" 2>/dev/null >"$text_file"; then
        return 1
    fi

    local text_size
    text_size=$(stat -c%s "$text_file" 2>/dev/null || echo 0)
    if [ "$text_size" -eq 0 ] || [ "$text_size" -gt "$MAX_TEXT_BYTES" ]; then
        return 0
    fi

    local hash
    hash=$(md5sum "$text_file" | cut -d' ' -f1)
    tr -d '\r' <"$text_file" | "$SCRIPT_PATH" "$DB_PATH" "$hash" "text/plain" 0 "" "$text_size"
    return 0
}

# Check for plain text - prefer UTF-8 charset to preserve unicode characters
if check_text_type 'text/plain;charset=utf-8'; then
    exit 0
elif check_text_type text/plain; then
    exit 0
fi
