# Benchmarks

Date: 2026-06-03

Environment:

- Hyprland live session: `WAYLAND_DISPLAY=wayland-1`.
- Active monitor count from `hyprctl monitors -j`: `1`.
- Existing VibeShell: active Quickshell process `/nix/store/.../quickshell -p /nix/store/...-vibeshell-shell-0.1.0/shell.qml`.
- vibeshellREzero: launched in safe overlay mode for measurement because current Quickshell VibeShell was still active in this session.

## Measured Results

| Metric | Existing VibeShell | vibeshellREzero | Notes |
| --- | ---: | ---: | --- |
| Idle RSS, single monitor | 631,100 KB | 110,004 KB | Fresh `scripts/benchmark.sh` sample after VibeShell-like UI and click-action changes. |
| Idle RSS, multi-monitor | Not testable | Not testable | Only one active monitor was reported by Hyprland. |
| Idle CPU usage | 4.097% | 0.000% | 10-second `/proc/$pid/stat` delta. |
| Startup time | Not measured | 119 ms | Startup-to-IPC-ready ping loop. Existing VibeShell startup was not restarted to avoid disrupting the active shell. |
| Frame/render activity while idle | Not measured | `idle_render_delta=0` | `renders=` counter stayed unchanged during 10-second idle sample. |
| Interaction responsiveness | Existing shell active | IPC/run/hide/quit tested | Workspace dispatch tested with Hyprland 0.55 Lua dispatcher expression. |
| RAM usage target | Baseline recorded | Lower in MVP sample | This is measured for the current MVP, not a full feature-parity shell. |

## Latest Raw Sample

```text
monitor_count=1
existing_vibeshell pid=3998 rss_kb=631100 idle_cpu_percent=4.097 sample_seconds=10.0
vibeshellREzero pid=27163 startup_ms=119 rss_kb=110004 idle_cpu_percent=0.000 sample_seconds=10.0
vibeshellREzero idle_render_delta=0
```

## Commands Used

```bash
cd /etc/nixos/asuraPc/vibeshellREzero
./scripts/benchmark.sh
```

Manual runtime checks:

```bash
VIBESHELLREZERO_LAYER=overlay VIBESHELLREZERO_EXCLUSIVE_ZONE=0 ./build/vibeshellREzero --config config/default.toml
./build/vibeshellREzero msg status
./build/vibeshellREzero msg run dashboard-widgets
./build/vibeshellREzero msg workspace 1
./build/vibeshellREzero msg hide
./build/vibeshellREzero msg quit
```

## Interpretation

The measured REzero MVP uses less memory and less idle CPU than the currently running Quickshell VibeShell process in this single-monitor session, and it does not redraw constantly while idle. This is not a final full-parity performance claim because several high-cost features are still placeholders or wrappers.

The current MVP still uses Cairo/Pango for text rasterization. Further memory reduction likely requires replacing that with a native glyph atlas/shaping path.
