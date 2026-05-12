# Script to sync current wallpaper with lock screen
{ pkgs, ... }:

{
  home.file.".local/bin/sync-lock-wallpaper" = {
    text = ''
      #!/usr/bin/env bash
      
      WALLPAPER_DIR="$HOME/.config/background"
      LOCK_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/Vibeshell"
      LOCK_WALLPAPER="$LOCK_DIR/lockscreen.png"
      TMP_LOCK_WALLPAPER="$LOCK_WALLPAPER.tmp"
      
      # Use provided wallpaper or default
      if [ -n "$1" ] && [ -f "$1" ]; then
        CURRENT_WALLPAPER="$1"
      else
        CURRENT_WALLPAPER="$WALLPAPER_DIR/126270092_p0.jpg"
      fi
      
      # Check if source wallpaper exists
      if [ -f "$CURRENT_WALLPAPER" ]; then
        mkdir -p "$LOCK_DIR"
      else
        echo "Wallpaper not found at $CURRENT_WALLPAPER"
        exit 1
      fi
    '';
    executable = true;
  };

  # Minimal packages for image handling
  home.packages = with pkgs; [
    imagemagick  # Only for format conversion when needed
  ];
}
