# Theming configuration
<<<<<<< HEAD
# Stylix owns the base theme. We add a few desktop-specific keys on top.
=======
# Stylix owns the base theme. We add Cinnamon/Nemo-specific keys.
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
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
