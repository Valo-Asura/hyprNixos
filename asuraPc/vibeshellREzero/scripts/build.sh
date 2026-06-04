#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v meson >/dev/null 2>&1 || ! command -v ninja >/dev/null 2>&1; then
  if [ "${VIBESHELLREZERO_IN_NIX:-0}" != "1" ] && command -v nix >/dev/null 2>&1; then
    exec env VIBESHELLREZERO_IN_NIX=1 nix develop "path:$ROOT" -c "$0" "$@"
  fi
fi

cd "$ROOT"
meson setup build --buildtype=debugoptimized "$@" || meson setup --reconfigure build "$@"
ninja -C build
