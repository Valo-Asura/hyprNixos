# X11 Qtile Session

Self-contained NixOS module for an extra **Qtile X11** login session.
It does not replace the existing Hyprland + Vibeshell Wayland session.

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
    ├── rofi/
    ├── picom.conf
    └── wallpapers/
```

## Behavior

- `modules/session.nix` adds a `Qtile (X11)` xsessions entry for `tuigreet`.
- Hyprland remains the default `tuigreet --cmd` session.
- Qtile starts with `qtile start -b x11 -c ~/.config/x11qtile/qtile/config.py`.
- Home Manager publishes only `~/.config/x11qtile/*`.
- No files are read from `~/Downloads/Cozytile-main` at runtime.
- Empty workspaces show a small `eww` desktop dashboard inspired by the referenced lock/home screen style.
- The dashboard closes automatically when a normal app window opens and returns when the current workspace is empty.

## Keybindings

- `Super + T` / `Super + Enter`: Kitty
- `Super + B`: Brave
- `Super + F`: Thunar
- `Super + W`: Rofi launcher
- `Super + Q`: Close focused window
- `Super + G`: Toggle floating
- `Super + J`: Toggle split
- `Super + Shift + F`: Toggle fullscreen
- `Super + Arrow`: Focus windows
- `Super + Ctrl + Arrow`: Move windows
- `Super + Shift + Arrow`: Resize windows
- `Super + 1..9`: Switch workspace
- `Super + Shift + 1..9`: Move window to workspace
- `Print`: Area screenshot to clipboard
- `Super + Print`: Fullscreen screenshot to `~/Pictures`
- `Super + Shift + Print`: Area screenshot to `~/Pictures`
- `Ctrl + L` / `Super + L`: Lock

## Rollback

Remove this import from `/etc/nixos/system/default.nix`:

```nix
../x11qtile
```

Then dry-build or switch as needed.
