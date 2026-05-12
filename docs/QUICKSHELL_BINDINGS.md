# Quickshell / Vibeshell Bindings Sheet

Checked on 2026-05-10 with `hyprctl binds -j` and `/etc/nixos/asuraPc/vibeshell/binds.json`.

## Where Bindings Live

- Nix static Hyprland binds: `/etc/nixos/asuraPc/hyprland/bindings.nix`
- Vibeshell default binds in repo: `/etc/nixos/asuraPc/vibeshell/binds.json`
- Vibeshell live user binds: `~/.config/Vibeshell/binds.json`
- Vibeshell bind editor: `SUPER+SHIFT+C` -> Settings -> Keybinds

Vibeshell applies its binds at runtime with `hyprctl keyword`. If a static Nix bind and Vibeshell bind use the same key combo, the Vibeshell bind can replace the static one in the live session.

## Edit Flow

1. Open Vibeshell settings with `SUPER+SHIFT+C`.
2. Select the `Keybinds` tab in the left settings rail.
3. Edit a Vibeshell system/dashboard bind, or add a custom bind.
4. Use Hyprland dispatchers such as `exec`, `workspace`, `movetoworkspace`, `killactive`, `layoutmsg`, `resizeactive`, or `togglespecialworkspace`.
5. Leave compositor layouts empty to apply in all layouts, or restrict the bind to selected layouts.
6. Verify live state:

```bash
hyprctl binds
hyprctl binds -j | jq -r '.[] | [.key, .dispatcher, .arg] | @tsv'
```

Flag reference:

- `l`: locked
- `e`: repeat
- `m`: mouse
- `r`: release

## Static Nix Binds

- `SUPER+Q`: close active window
- `SUPER+H`: exit Hyprland
- `SUPER+F`: Thunar
- `SUPER+G`: toggle floating
- `SUPER+J`: toggle split via `layoutmsg`
- `SUPER+B`: Brave
- `SUPER+T`: Kitty
- `SUPER+I`: IDE / Code
- `SUPER+E`: Telegram
- `SUPER+W`: Wofi
- `CTRL+L` or `SUPER+L`: lock screen
- `SUPER+P`: static wallpaper
- `SUPER+SHIFT+P`: animated wallpaper
- `SUPER+ALT+P`: sync current wallpaper to lock screen
- `Print`: screenshot selection to clipboard
- `SUPER+Print`: full screenshot to file
- `SUPER+SHIFT+Print`: selection screenshot to file
- `SUPER+SHIFT+E`: emoji picker
- `SUPER+F2`: night shift

## Vibeshell Dashboard

- `SUPER+A`: Assistant
- `SUPER+V`: Clipboard
- `SUPER+PERIOD`: Emoji
- `SUPER+N`: Notes
- `ALT+T`: Tmux
- `SUPER+COMMA`: Wallpapers
- `SUPER+SPACE`: Widgets

## Vibeshell System

- `SUPER+SHIFT+C`: Config
- `SUPER+L`: Lock screen
- `ALT+TAB`: Overview
- `SUPER+ESCAPE`: Power menu
- `SUPER+S`: Tools
- `SUPER+SHIFT+S`: Screenshot tool
- `SUPER+SHIFT+R`: Screen recorder
- `SUPER+SHIFT+A`: Lens
- `SUPER+ALT+B`: Reload Vibeshell
- `SUPER+CTRL+ALT+B`: Quit Vibeshell

## Vibeshell Custom Window / Workspace Binds

- `SUPER+C`: close window
- `SUPER+1` through `SUPER+0`: workspace 1 through 10
- `SUPER+SHIFT+1` through `SUPER+SHIFT+0`: move window to workspace 1 through 10
- `SUPER+mouse_down` / `SUPER+mouse_up`: previous / next occupied workspace
- `SUPER+SHIFT+Z` / `SUPER+SHIFT+X`: previous / next occupied workspace
- `SUPER+Z` / `SUPER+X`: previous / next workspace
- `SUPER+mouse:272`: drag window
- `SUPER+mouse:273`: resize window
- `SUPER+SHIFT+V`: toggle special workspace
- `SUPER+ALT+V`: move to special workspace
- `SUPER+Arrow`: focus direction
- `SUPER+SHIFT+Arrow`: move window direction
- `SUPER+ALT+Arrow`: resize active window

## Checked Conflicts

Resolved conflicts:

- `SUPER+C` is Vibeshell close window, so the IDE static bind moved to `SUPER+I`.
- `SUPER+V` is Vibeshell clipboard, so static floating moved to `SUPER+G`.

Intentional duplicates:

- `SUPER+L` appears in both static Nix and Vibeshell config, but both run a lock command.
