# Isolated packages for the low-memory X11 Qtile session.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    xinit # tuigreet X11 session wrapper uses startx
    xset # DPMS/screensaver controls for Qtile caffeine and lock scripts
    xsetroot # solid-color fallback wallpaper and cursor
    xinput # input debugging for the X11 session
    xmodmap # ensure SUPER maps to mod4 for Qtile binds
    xrandr # monitor geometry/debugging
    i3lock-color # X11-native lockscreen for Qtile
    redshift # X11 night mode color temperature toggle
    rofi # X11 application launcher and powermenu
    copyq # Clipboard history, started on demand by Super+V
    feh # X11 wallpaper setter
    maim # Screenshot utility for X11
    xclip # Clipboard utility for X11 screenshots
    xdotool # X11 automation tool
    dunst # X11 notification daemon
    font-awesome # Font icons used by fallback Qtile widgets
    libnotify # notify-send for Qtile mode toggles
    pamixer # CLI sound controller for widgets
    brightnessctl
    fastfetch
    playerctl
    kitty
    brave
    thunar
    telegram-desktop
  ];
}
