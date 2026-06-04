#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/scripts/build.sh"

BIN="$ROOT/build/vibeshellREzero"
ldd "$BIN" | tee "$ROOT/build/ldd.txt"

if rg -i 'qt|qml|quick|javascript|electron|gtk|webkit' "$ROOT/build/ldd.txt"; then
  echo "Forbidden runtime dependency found" >&2
  exit 1
fi

"$BIN" --help >/dev/null
"$BIN" --version >/dev/null

echo "vibeshellREzero non-GUI tests passed"

