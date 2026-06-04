# Feature Parity Audit

## Sources Inspected

- Current VibeShell source directory: `/etc/nixos/asuraPc/vibeshell`.
- Baseline VibeShell run workflow observed before the REzero autostart switch: Home Manager built a Quickshell package and `vibeshell-start` launched `quickshell -p .../vibeshell-shell-0.1.0/shell.qml`. Existing binds called `vibeshell run ...`.
- Noctalia reference directory: `/home/asura/Downloads/noctalia-shell-5`, used read-only for native architecture and UI behavior clues.

## Reference Clues Reused

- Native C++/Meson structure.
- Wayland layer-shell surface ownership.
- EGL/OpenGL ES rendering direction.
- Explicit app state instead of QML bindings.
- Hyprland IPC integration as a first-class module.
- Bar-first implementation order.

No QML, Qt, Quickshell, or JavaScript code was copied into this rewrite.

## Matrix

| Feature | Existing Behavior | Reference Clues | Native Implementation Plan | Status | Validation Method |
| --- | --- | --- | --- | --- | --- |
| Top bar / panel | Quickshell top bar with pill groups, active window, status widgets, launcher/dock controls. | Native layer surface and GLES renderer. | Two-row VibeShell-like `wlr-layer-shell` bar rendered with GLES and native click targets. | Implemented MVP | Live screenshot `docs/screenshots/20260603-125011-vibeshellREzero-vibeshell-like.png`; wrapper toggle test passed. |
| Workspace indicators | Current bar shows workspace indicators and active workspace. | Explicit Hyprland IPC state. | Poll `j/workspaces` and `j/activeworkspace`; click dispatches `workspace N`. | Implemented MVP | IPC status plus visual screenshot; click path implemented, not exhaustively tested across all workspaces. |
| Active window title | Current bar displays focused app/title. | Hyprland IPC active window state. | Poll `j/activewindow` and render truncated title. | Implemented MVP | IPC returned VS Code title during live test. |
| Clock/date | Current bar displays time and date/weather style groups. | Bar clock widget. | Render HH:MM clock. | Implemented MVP | Screenshot shows `12:06`; date not displayed yet. |
| System tray | Current shell has tray/status groups. | Native status modules. | Requires StatusNotifierWatcher/DBus implementation. | Not started | None. |
| Network/Bluetooth status | Current shell shows network; Bluetooth likely through status/controls. | System modules and DBus patterns. | Network reads `/sys/class/net`; Bluetooth DBus planned. | Network MVP only | IPC status and screenshot show `net up`. |
| Audio controls | Current shell shows volume and has controls. | System/audio modules. | MVP shells out to `wpctl get-volume`; future native PipeWire/WirePlumber. | Indicator MVP | Screenshot shows `vol 69%`; no slider/control. |
| Battery/power | Current shell has power/status indicators. | System modules. | Read `/sys/class/power_supply/BAT*/capacity`. | Implemented when battery exists | Desktop test had no battery value. |
| App launcher | Current shell includes launcher. | Launcher module in reference. | `vibeshell run launcher` and bar click open a native placeholder overlay; full app search is still planned. | Placeholder | Packaged wrapper toggle test passed. |
| Notification center | Current shell includes notifications. | DBus notification module. | Implement `org.freedesktop.Notifications` server. | Not started | None. |
| Control center / quick settings | Current shell has dashboard/control widgets. | Control center layout ideas. | Native placeholder overlay responds to `run dashboard-*` and bar controls click targets; full widgets still planned. | Placeholder | `msg run dashboard-widgets`; screenshot captured. |
| Wallpaper / desktop components | Current VibeShell has wallpaper/video helpers and desktop can be configured. | Noctalia backdrop ideas. | Out of MVP; keep separate from shell bar. | Not started | None. |
| Lock/session controls | Current shell has lock/logout/power actions. | Session controls. | Compatibility wrapper maps lock/lockscreen to `hyprlock`; powermenu placeholder exists. | Partial | `vibeshell lock`; `msg run powermenu`. |
| Animations | Current shell has QML animations and performance toggles. | Explicit animation timing. | Add deterministic animation scheduler. | Not started | None. |
| Theme/configuration | Current shell has declarative theme defaults. | Config/theme modules. | `config/default.toml` colors, sizes, font. | Implemented MVP | Config loaded in runtime logs. |
| Multi-monitor behavior | Current shell can run across outputs. | Output-aware surface manager. | Create one bar surface per `wl_output`. | Not started | None. |
| Hyprland IPC integration | Current shell uses Hyprland state/actions. | Native IPC module. | Unix socket requests and Lua-mode workspace dispatch. | Implemented MVP | `msg status`; `msg workspace 1` returned `ok` with `hl.dsp.focus(...)`. |
| Clipboard manager | Current shell runs clipboard watcher/db. | Existing shell scripts. | Native or helper-backed module later. | Not started | None. |
| Dock | Current shell has dock enabled. | Dock/panel concepts. | Separate layer surface after bar. | Not started | None. |
| Screenshot tools | Current shell integrates screenshot actions. | Utility action model. | Compatibility wrapper maps screenshot commands to `grim`/`slurp`; native UI flow still planned. | Wrapper only | `vibeshell run screenshot`; `vibeshell run screenshot-area`. |
| AI/custom widgets | Current shell has custom assistant/widgets. | Plugin boundary ideas. | Plugin/widget API after native core stabilizes. | Not started | None. |

## Current Parity Summary

The current implementation is a validated bar-first MVP with a closer VibeShell-like two-row UI, native click targets, and command compatibility wrappers. It is not full VibeShell parity. Real tray, dashboard, dock, clipboard, notifications, AI, wallpaper, and multi-monitor surface management remain staged work.
