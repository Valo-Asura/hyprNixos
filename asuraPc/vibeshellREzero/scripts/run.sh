#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -x "$ROOT/build/vibeshellREzero" ]; then
  "$ROOT/scripts/build.sh"
fi

exec "$ROOT/build/vibeshellREzero" "$@"

