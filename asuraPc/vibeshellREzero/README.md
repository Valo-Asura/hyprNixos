# vibeshellREzero

Native C++20 Wayland/OpenGL ES shell MVP for Hyprland.

This project is separate from the active VibeShell tree. It does not replace or modify `/etc/nixos/asuraPc/vibeshell`, and it uses `/home/asura/Downloads/noctalia-shell-5` only as a read-only architecture/UI reference.

## Current Status

Implemented: VibeShell-like two-row native bar MVP with wlr-layer-shell, EGL/OpenGL ES rendering, Cairo/Pango text rasterization, Hyprland IPC polling, clickable workspace dispatch, clickable module placeholders, clock, active title, basic network/volume/battery indicators, local IPC, config loading, screenshots, and benchmark script.

Not fully implemented yet: native launcher, full dashboard, notifications, tray, dock, clipboard manager, wallpaper controls, AI panel, richer animations, multi-monitor per-output bars, and plugin runtime. Some commands are wired as placeholders or compatibility wrappers.

## Dependencies

Runtime/build dependencies are intentionally small and native:

- C++20 compiler
- Meson and Ninja
- Wayland client and wayland-scanner
- wlr-layer-shell protocol XML
- EGL and OpenGL ES
- Cairo and Pango for current MVP text rasterization
- Fontconfig

Forbidden dependencies checked by `scripts/test.sh`: Qt, QML, Quickshell, JavaScript, Electron, GTK, and WebKit.

## Build

```bash
cd /etc/nixos/asuraPc/vibeshellREzero
./scripts/build.sh
```

The script enters this project flake with `nix develop path:/etc/nixos/asuraPc/vibeshellREzero` when Meson/Ninja are unavailable in the current shell. It does not require staging files in the root NixOS repo.

## Run Under Hyprland

Standalone exclusive-zone bar:

```bash
cd /etc/nixos/asuraPc/vibeshellREzero
./scripts/run.sh
```

Safe overlay test mode while current VibeShell is still running:

```bash
VIBESHELLREZERO_LAYER=overlay VIBESHELLREZERO_EXCLUSIVE_ZONE=0 ./build/vibeshellREzero --config config/default.toml
```

IPC:

```bash
./build/vibeshellREzero msg status
./build/vibeshellREzero msg refresh
./build/vibeshellREzero msg workspace 2
./build/vibeshellREzero msg run dashboard-widgets
./build/vibeshellREzero msg hide
./build/vibeshellREzero msg quit
```

Compatibility wrapper after NixOS rebuild. Common VibeShell module commands now route to native REzero placeholders; `app-launcher`/`drun`/`wofi` remain explicit Wofi fallbacks:

```bash
vibeshell run dashboard-widgets
vibeshell run launcher
vibeshell run powermenu
vibeshell run app-launcher
vibeshell run screenshot
vibeshell quit
```

## Test And Benchmark

```bash
./scripts/test.sh
./scripts/capture.sh current-vibeshell-baseline
./scripts/benchmark.sh
```

See:

- `docs/architecture.md`
- `docs/feature-parity.md`
- `docs/testing.md`
- `docs/benchmarks.md`

## NixOS Notes

This directory includes its own `flake.nix` and `package.nix`.

Current NixOS wiring:

- `asuraPc/system/vibeshell.nix` installs this package instead of importing the old Quickshell VibeShell module.
- `asuraPc/hyprland/default.nix` autostarts `${vibeshellREzero}/bin/vibeshellREzero` and stops old Quickshell VibeShell, Noctalia, and skwd-wall processes first.
- Noctalia/skwd-wall imports remain disabled in `asuraPc/system/default.nix`.
