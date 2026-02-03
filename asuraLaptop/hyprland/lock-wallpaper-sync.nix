# Script to sync current wallpaper with lock screen
{ pkgs, ... }:

{
  home.file.".local/bin/sync-lock-wallpaper" = {
    text = ''
      #!/usr/bin/env bash
      
      WALLPAPER_DIR="$HOME/.config/background"
      LOCK_DIR="/etc/nixos/asuraLaptop/hyprland/lock-images"
      LOCK_WALLPAPER="$LOCK_DIR/lockscreen.png"
      
      # Use provided wallpaper or default
      if [ -n "$1" ] && [ -f "$1" ]; then
        CURRENT_WALLPAPER="$1"
      else
        CURRENT_WALLPAPER="$WALLPAPER_DIR/126270092_p0.jpg"
      fi
      
      # Check if source wallpaper exists
      if [ -f "$CURRENT_WALLPAPER" ]; then
        # Ensure lock directory exists
        sudo mkdir -p "$LOCK_DIR"
        
        # Simple copy for performance (no conversion unless needed)
        if [[ "$CURRENT_WALLPAPER" == *.png ]]; then
          sudo cp "$CURRENT_WALLPAPER" "$LOCK_WALLPAPER"
        else
          # Only convert if not PNG
          if command -v convert >/dev/null 2>&1; then
            sudo convert "$CURRENT_WALLPAPER" "$LOCK_WALLPAPER"
          else
            sudo cp "$CURRENT_WALLPAPER" "$LOCK_WALLPAPER"
          fi
        fi
        
        echo "Lock screen wallpaper updated from: $CURRENT_WALLPAPER"
        sudo chmod 644 "$LOCK_WALLPAPER"
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