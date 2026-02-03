# Desktop environment configuration
{ inputs, pkgs, ... }:

{
  imports = [
    ./hyprland
    ./theming
    ./applications
    ./browsers.nix
    ./zen-browser.nix
  ];
}
