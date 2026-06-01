# X11 Qtile Session

Self-contained NixOS module for an extra **Qtile X11** login session.
It does not replace or modify the existing Hyprland + Vibeshell Wayland session.

## Structure

```text
x11qtile/
├── default.nix
├── modules/
│   ├── packages.nix
│   ├── session.nix
│   └── home.nix
└── config/
    ├── qtile/
    │   ├── config.py
    │   ├── keybindings.py
    │   ├── theme.py
    │   ├── widgets.py
    │   └── autostart.sh
    ├── rofi/
    ├── picom.conf
    └── wallpapers/
```

## Behavior & Optimizations

- `modules/session.nix` adds a `Qtile (X11)` xsessions entry for `tuigreet`.
- Hyprland remains the default `tuigreet --cmd` session.
- Qtile starts with `qtile start -b x11 -c ~/.config/x11qtile/qtile/config.py`.
- Home Manager publishes only `~/.config/x11qtile/*`.
- **Compositor**: Picom is configured with GLX hardware acceleration and VSync to run cleanly at 165Hz (Nvidia GTX 1070).
- **MIME Config**: System default applications are updated to Brave Browser for web (`.html`/schemes) and PDF files.
- **System Packages Added**:
  - **Helium Browser**: Privacy-focused browser installed via community flake.
  - **Zed Editor**: Modern GPU-accelerated code editor (`zed-editor`).
  - **Vim**: Pre-configured wrapped Vim custom package (`vimWrapped`) with customized `.vimrc` settings.
  - **Brave**: Removed from system-wide package list; now managed user-wide via Home Manager.
- **Low Memory Target**: Whole-system idle memory usage runs at **< 400MB RAM**:
  - Eww & Fabric bars are removed in favor of a native Qtile status bar (`widgets.py`).
  - Bar widgets parse memory and CPU metrics directly via `/proc` filesystem files (`/proc/loadavg` and `/proc/meminfo`) to avoid shell execution overhead.
  - Weather information is downloaded in a background loop (`autostart.sh`) every 30 minutes, keeping the bar UI non-blocking.
  - **MySQL**: Optimized with `performance_schema = 0` and reduced InnoDB buffer pools (idle dropped from ~470MB to ~40MB).
  - **MongoDB**: Constrained WiredTiger engine cache to a maximum of **256MB** (preventing default allocations of up to 7.5GB).

## Status Bar Widgets

1. **NixOS Logo** (``): Triggers Rofi menu on left click.
2. **Workspaces**: Pacman ghosts (`󰊠`) showing active (green), populated (white), and empty (dark grey) states.
3. **Media Player**: Track name/artist fetched from `playerctl`.
4. **Fastfetch Icon** (`󰈸`)
5. **Disk Free** (``)
6. **CPU Load** (``)
7. **Memory Used** (`󰍛`)
8. **Network Speed** (`󰇚` & `󰕒`): Shared double-rate cache poller.
9. **Volume** (``): Inline sound level and mute toggle.
10. **Weather** (``): Cached `wttr.in` output.
11. **Uptime** (`󰔚`): Active time read from `/proc/uptime`.
12. **12-Hour Clock** (``): Time formatted with AM/PM.
13. **Session Action** (`󰍃`): Red logout menu button.

## Keybindings

- `Super + T` / `Super + Enter`: Kitty
- `Super + B`: Brave
- `Super + F`: Thunar
- `Super + I`: VSCode
- `Super + E`: Telegram
- **`Super + A`**: Rofi application launcher
- `Super + V`: CopyQ clipboard history
- `Super + Ctrl + V`: Paste CopyQ current item
- `Super + Q`: Close focused window
- `Super + G`: Toggle floating
- `Super + S`: Toggle split
- `Super + Shift + F`: Toggle fullscreen
- `Super + Arrow` / `Super + H/J/K/L`: Focus windows
- `Super + Ctrl + Arrow` / `Super + Ctrl + H/J/K/L`: Move windows
- `Super + Shift + Arrow` / `Super + Shift + H/J/K/L`: Resize windows
- `Super + 1..9`: Switch workspace
- `Super + Shift + 1..9`: Move window to workspace
- `Print`: Area screenshot to clipboard
- `Super + Print`: Screenshot options menu
- `Super + Shift + Print`: Area screenshot to file and clipboard
- `Ctrl + Print`: Fullscreen screenshot to clipboard
- `Super + Ctrl + Print`: Fullscreen screenshot to file and clipboard
- `Super + Shift + Escape`: Lock

## Rollback

Remove this import from `/etc/nixos/system/default.nix`:

```nix
../x11qtile
```

Then dry-build or switch as needed.
