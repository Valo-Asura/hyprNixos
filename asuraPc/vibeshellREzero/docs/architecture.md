# Architecture

## Boundaries

- Existing VibeShell source: `/etc/nixos/asuraPc/vibeshell`, read-only reference.
- Noctalia reference source: `/home/asura/Downloads/noctalia-shell-5`, read-only reference.
- New native implementation: `/etc/nixos/asuraPc/vibeshellREzero`.

## Stack

- Language: C++20.
- Build system: Meson with a local Nix flake dev shell.
- Shell protocol: Wayland client plus `wlr-layer-shell`.
- Rendering: EGL context over `wl_egl_window`, OpenGL ES textured quad.
- Text/UI rasterization: Cairo/Pango in the MVP, uploaded as an RGBA texture.
- IPC: Hyprland Unix socket for workspace/title state and a local Unix socket for `vibeshellREzero msg ...`.

## Runtime Flow

1. Load `config/default.toml`.
2. Connect to Wayland and bind `wl_compositor`, `wl_seat`, and `zwlr_layer_shell_v1`.
3. Create a layer-shell bar surface anchored to top/left/right.
4. Wait for compositor configure, create a `wl_egl_window`, initialize EGL/GLES.
5. Poll Wayland FD, timer FD, and local IPC socket in one deterministic loop.
6. Refresh Hyprland/system state on timer or IPC request.
7. Redraw only when visible state changes or the compositor resizes the surface.
8. Shut down renderer, IPC socket, layer surface, and Wayland connection through RAII-style owners.

## Implemented Modules

- `src/app`: event loop, state refresh, redraw gating.
- `src/wayland`: registry, layer surface, pointer input, EGL window ownership.
- `src/renderer`: Cairo/Pango paint pass, texture upload, GLES render pass.
- `src/state`: config parsing, Hyprland IPC, system indicators.
- `src/ipc`: local Unix socket server/client commands.
- `scripts`: build, run, test, capture, benchmark.

## Known Architecture Debt

- Cairo/Pango makes the MVP practical but still pulls GLib/Pango/Cairo/X11 transitive libraries. Future text rendering should move to a native atlas/shaping path if lower memory is required.
- Hyprland state is currently polled instead of consuming `.socket2.sock` event stream.
- Multi-monitor handling is not implemented yet; current MVP creates one layer surface.
- The plugin boundary is planned but not implemented.
