#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/docs/screenshots"
mkdir -p "$OUT"

if ! command -v grim >/dev/null 2>&1; then
  echo "grim not found; enter nix develop $ROOT first" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
LABEL="${1:-screenshot}"
LABEL="${LABEL//[^A-Za-z0-9_.-]/-}"
grim "$OUT/$STAMP-$LABEL.png"
echo "$OUT/$STAMP-$LABEL.png"
