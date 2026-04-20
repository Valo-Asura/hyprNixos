# Theming configuration
# Stylix owns the base theme. We add a few desktop-specific keys on top.
{ ... }:

{
  dconf.enable = true;

  dconf.settings = {
    "org.cinnamon.desktop.interface" = {
      gtk-theme = "Stylix";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 18;
    };
  };
}
