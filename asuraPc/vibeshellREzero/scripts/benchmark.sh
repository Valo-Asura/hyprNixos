#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/build/vibeshellREzero"

"$ROOT/scripts/build.sh" >/dev/null

cpu_ticks() {
  awk '{print $14 + $15}' "/proc/$1/stat"
}

measure_cpu() {
  local pid="$1"
  local seconds="${2:-10}"
  local hz
  hz="$(getconf CLK_TCK)"
  local t1 w1 t2 w2 rss
  t1="$(cpu_ticks "$pid")"
  w1="$(date +%s%N)"
  sleep "$seconds"
  t2="$(cpu_ticks "$pid")"
  w2="$(date +%s%N)"
  rss="$(ps -p "$pid" -o rss= | tr -d ' ')"
  awk -v t1="$t1" -v t2="$t2" -v w1="$w1" -v w2="$w2" -v hz="$hz" -v rss="$rss" \
    'BEGIN { secs=(w2-w1)/1000000000; cpu=((t2-t1)/hz)/secs*100; printf "rss_kb=%s idle_cpu_percent=%.3f sample_seconds=%.1f\n", rss, cpu, secs }'
}

render_count() {
  "$BIN" msg status 2>/dev/null | sed -n 's/^renders=\([0-9][0-9]*\).*/\1/p'
}

monitor_count="$(hyprctl monitors -j 2>/dev/null | jq 'length' 2>/dev/null || echo unknown)"
printf 'monitor_count=%s\n' "$monitor_count"

existing_pid="$(ps -eo pid,args | awk '/vibeshell-shell-0\.1\.0\/shell\.qml/ && !/awk/ {print $1; exit}')"
if [[ -n "${existing_pid:-}" ]]; then
  printf 'existing_vibeshell pid=%s ' "$existing_pid"
  measure_cpu "$existing_pid" 10
else
  echo "existing_vibeshell pid=missing"
fi

VIBESHELLREZERO_LAYER=overlay VIBESHELLREZERO_EXCLUSIVE_ZONE=0 "$BIN" --config "$ROOT/config/default.toml" \
  >"$ROOT/build/benchmark-script-runtime.log" 2>&1 &
pid="$!"
start_ns="$(date +%s%N)"
for _ in $(seq 1 50); do
  if "$BIN" msg ping >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
ready_ns="$(date +%s%N)"
startup_ms="$(( (ready_ns - start_ns) / 1000000 ))"
sleep 3
renders_before="$(render_count || true)"
printf 'vibeshellREzero pid=%s startup_ms=%s ' "$pid" "$startup_ms"
measure_cpu "$pid" 10
renders_after="$(render_count || true)"
if [[ -n "${renders_before:-}" && -n "${renders_after:-}" ]]; then
  printf 'vibeshellREzero idle_render_delta=%s\n' "$((renders_after - renders_before))"
fi
"$BIN" msg quit >/dev/null || true
wait "$pid" || true
