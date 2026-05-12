# Wallpaper management utilities for Hyprland
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Minimal wallpaper tools for performance
    awww # Only when needed for animated wallpapers
  ];

  # Script for switching wallpapers
  home.file.".local/bin/wallpaper-switch" = {
    text = ''
      #!/usr/bin/env bash

      WALLPAPER_DIR="$HOME/.config/background"

      # Function to sync lock screen wallpaper
      sync_lock_wallpaper() {
        if [ -n "$1" ] && [ -f "$1" ]; then
          sync-lock-wallpaper "$1"
        else
          sync-lock-wallpaper
        fi
      }

      case "$1" in
        "static")
          # Use hyprpaper for static wallpapers (best performance)
          pkill awww 2>/dev/null || true
          systemctl --user restart hyprpaper
          sync_lock_wallpaper
          ;;
        "animated")
          # Use awww for animated wallpapers and transitions
          pkill hyprpaper 2>/dev/null || true
          awww init
          if [ -n "$2" ]; then
            awww img "$2" --transition-type fade --transition-duration 1
            sync_lock_wallpaper "$2"
          else
            awww img "$WALLPAPER_DIR/126270092_p0.jpg" --transition-type fade --transition-duration 1
            sync_lock_wallpaper
          fi
          ;;
        *)
          echo "Usage: wallpaper-switch {static|animated} [file]"
          echo "  static   - Use hyprpaper (best performance)"
          echo "  animated - Use awww for animated wallpapers"
          ;;
      esac
    '';
    executable = true;
  };
}
