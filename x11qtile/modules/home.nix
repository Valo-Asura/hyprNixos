# home.nix
# Declarative Qtile window manager integration and Home Manager settings
{ ... }:

{
  # Enable the X11 window manager Qtile
  services.xserver.windowManager.qtile = {
    enable = true;
  };

  # Home Manager publishes only the isolated X11 Qtile namespace.
  home-manager.users.asura = {
    xdg.configFile."x11qtile/qtile".source = ../config/qtile;
    xdg.configFile."x11qtile/rofi".source = ../config/rofi;
    xdg.configFile."x11qtile/picom.conf".source = ../config/picom.conf;
    xdg.configFile."x11qtile/wallpapers".source = ../config/wallpapers;
  };
}
