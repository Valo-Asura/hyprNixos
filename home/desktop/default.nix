# Desktop environment configuration
{ inputs, pkgs, ... }:

{
  imports = [
    ./hyprland
    ./theming
    ./applications
    ./browsers.nix
    ./file-manager.nix
<<<<<<< HEAD
=======
    ./zen-browser.nix
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  ];
}
