# packages.nix
# Isolated packages for X11 Qtile session
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    xinit # tuigreet X11 session wrapper uses startx
    xsetroot # solid-color fallback wallpaper
    picom # X11 compositor for transparency and shadows
    rofi # X11 application launcher and powermenu
    feh # X11 wallpaper setter
    maim # Screenshot utility for X11
    xclip # Clipboard utility for X11 screenshots
    xdotool # X11 automation tool
    pywal # Optional color generation from wallpapers
    dunst # X11 notification daemon
    font-awesome # Font icons used in the Qtile bar
    pamixer # CLI sound controller for widgets
    brightnessctl
    playerctl
    networkmanagerapplet
    kitty
    brave
    thunar
    telegram-desktop
  ];
}
