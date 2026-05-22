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

WL_PASTE_TIMEOUT="${VIBESHELL_CLIPBOARD_WL_PASTE_TIMEOUT:-1s}"
MAX_TEXT_BYTES="${VIBESHELL_CLIPBOARD_MAX_TEXT_BYTES:-524288}"
MAX_URI_BYTES="${VIBESHELL_CLIPBOARD_MAX_URI_BYTES:-65536}"
MAX_IMAGE_BYTES="${VIBESHELL_CLIPBOARD_MAX_IMAGE_BYTES:-8388608}"

# Check for files first (text/uri-list)
URI_FILE=$(mktemp)
trap 'rm -f "$URI_FILE"' EXIT
if timeout "$WL_PASTE_TIMEOUT" wl-paste --type text/uri-list 2>/dev/null >"$URI_FILE"; then
    URI_SIZE=$(stat -c%s "$URI_FILE" 2>/dev/null || echo 0)
    if [ "$URI_SIZE" -eq 0 ] || [ "$URI_SIZE" -gt "$MAX_URI_BYTES" ]; then
        exit 0
    fi

    HASH=$(tr -d '\r' <"$URI_FILE" | md5sum | cut -d' ' -f1)
    
    # Get file size if it's a local file
    FILE_SIZE=0
    FILE_PATH=$(tr -d '\r' <"$URI_FILE" | sed 's|^file://||')
    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
    fi
    
    tr -d '\r' <"$URI_FILE" | "$SCRIPT_PATH" "$DB_PATH" "$HASH" "text/uri-list" 0 "" "$FILE_SIZE"
    exit 0
fi

# Check for images
IMAGE_MIME=$(timeout "$WL_PASTE_TIMEOUT" wl-paste --list-types 2>/dev/null | grep -m1 '^image/' || true)
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
        
    if ! timeout "$WL_PASTE_TIMEOUT" wl-paste --type "$IMAGE_MIME" 2>/dev/null >"$BINARY_PATH"; then
        rm -f "$BINARY_PATH"
        exit 0
    fi
        
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

check_text_type() {
    local mime="$1"
    local text_file
    text_file=$(mktemp)
    trap 'rm -f "$text_file"' RETURN

    if ! timeout "$WL_PASTE_TIMEOUT" wl-paste --type "$mime" 2>/dev/null >"$text_file"; then
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
