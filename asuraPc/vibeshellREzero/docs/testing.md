# Testing Report

Date: 2026-06-03

## Build Verification

Command:

```bash
cd /etc/nixos/asuraPc/vibeshellREzero
./scripts/build.sh
```

Result: passed.

Nix package command:

```bash
nix build path:/etc/nixos/asuraPc/vibeshellREzero --print-build-logs
```

Result: passed. The package installs `vibeshellREzero`, `vibeshell-zero`, and compatibility wrapper `vibeshell`.

Full system dry-build:

```bash
nixos-rebuild dry-build --flake /etc/nixos#nixos
```

Result: passed after wiring `vibeshellREzero` as a root `path:` flake input.

Notes:

- Meson generated `wlr-layer-shell` client code.
- Initial protocol edit that removed `get_popup` was reverted because it changed request opcodes and Hyprland rejected the client.
- A minimal `xdg_popup_interface` stub was added only to preserve generated-code linkage while keeping correct layer-shell request order.

## Dependency Verification

Command:

```bash
./scripts/test.sh
```

Result: passed.

Observed forbidden dependency check: no Qt, QML, Quickshell, JavaScript, Electron, GTK, or WebKit runtime dependency in `ldd`.

Allowed transitive libraries currently include Cairo, Pango, GLib, Fontconfig, Wayland, EGL, GLES, and X11 libraries pulled by Cairo/Pango.

## Runtime Verification

Live environment was available:

- `WAYLAND_DISPLAY=wayland-1`
- `HYPRLAND_INSTANCE_SIGNATURE=39d7e209c79d451efab1b21151d5938289da838d_1780467850_1462820024`
- `XDG_RUNTIME_DIR=/run/user/1000`

Successful run:

```bash
VIBESHELLREZERO_LAYER=overlay VIBESHELLREZERO_EXCLUSIVE_ZONE=0 ./build/vibeshellREzero --config config/default.toml
./build/vibeshellREzero msg status
./build/vibeshellREzero msg run dashboard-widgets
./build/vibeshellREzero msg workspace 1
./build/vibeshellREzero msg hide
./build/vibeshellREzero msg quit
```

Observed status:

```text
renders=3 workspace=1 title="application.cpp - nixos - Visual Studio Code" clock=12:50 network=up overlay=dashboard-widgets volume=69%
```

Runtime log showed EGL/GLES renderer initialization, IPC socket creation, and clean shutdown.

Live load check:

```text
systemd-run --user --unit=vibeshellREzero-live --collect /etc/nixos/result/bin/vibeshellREzero --config /etc/nixos/result/share/vibeshellREzero/config/default.toml
```

Result: passed. `vibeshellREzero-live.service` was active, `msg status` returned current workspace/title/status, and `pgrep -af 'quickshell|vibeshellREzero|noctalia|skwd'` showed only `vibeshellREzero`.

Packaged compatibility wrapper check:

```text
vibeshell run launcher -> showing launcher
vibeshell run launcher -> hidden
vibeshell run powermenu -> showing powermenu
```

Result: passed. Common VibeShell module commands now route to native REzero placeholder overlays instead of the old Quickshell IPC path.

Autostart wiring:

- `asuraPc/system/vibeshell.nix` installs `inputs.vibeshellREzero.packages...default` instead of importing the old Quickshell VibeShell module.
- `asuraPc/hyprland/default.nix` launches `${vibeshellREzero}/bin/vibeshellREzero` from the existing `hyprland.start` startup wrapper.
- The startup wrapper stops Noctalia user services, `skwd-daemon.service`, old `vibeshell-shell.*shell.qml` Quickshell instances, and live `skwd-daemon`/`skwd-paper` processes before launching REzero.
- Noctalia and skwd-wall imports remain commented out in `asuraPc/system/default.nix`.

## Screenshot Validation

Captured:

- Baseline current VibeShell: `docs/screenshots/20260603-120343-current-vibeshell-baseline.png`
- First rewrite exclusive-zone overlay: `docs/screenshots/20260603-120448-vibeshellREzero-overlay.png`
- Rewrite safe no-exclusive overlay: `docs/screenshots/20260603-120603-vibeshellREzero-overlay-no-exclusive.png`
- VibeShell-like two-row UI with dashboard overlay: `docs/screenshots/20260603-125011-vibeshellREzero-vibeshell-like.png`
- Current packaged REzero with launcher overlay: `docs/screenshots/20260603-130638-vibeshellREzero-current-launcher-overlay.png`

Result:

- The rewrite bar now renders a VibeShell-like two-row structure with top title/status groups and lower workspace/action groups.
- Workspaces, active title, waveform-style center segment, network, volume, clock, and dashboard placeholder overlay are visible.
- Safe overlay mode avoids moving the current desktop while VibeShell is still active.
- Bar buttons now have native hit-testing for launcher/dashboard/overview/presets/tools/notes/controls/config/powermenu placeholders.

Remaining visual differences:

- Current VibeShell has real launcher/dashboard/clipboard/AI/tray/dock modules; REzero currently has native placeholder overlays or command wrappers for these.
- Iconography is approximated with text labels until a native icon/text atlas is implemented.
- Current VibeShell's rich dock and full dashboard layouts are not implemented.

## Stability Fixes During Testing

- Restored `get_popup` request order in `wlr-layer-shell` XML after Hyprland reported invalid protocol arguments.
- Added no-op handlers for modern `wl_pointer` events to avoid abort on pointer frame events.
- Added redraw gating to avoid unnecessary GLES redraws when timer-polled state has not changed.
- Updated workspace dispatch to use the verified Hyprland 0.55 Lua expression `hl.dsp.focus({ workspace = "1" })`.
- Added local render counter evidence; idle benchmark reported `idle_render_delta=0`.

## Not Yet Validated

- Multi-monitor bars.
- System tray.
- Notification server.
- Launcher/control-center overlays.
- Full workspace click coverage across multiple workspaces.
- Long-running soak test.
- GPU activity through external profiler.
