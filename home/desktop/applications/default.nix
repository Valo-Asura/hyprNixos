# Desktop applications
{ inputs, pkgs, ... }:

{
  imports = [
    ../../../asuraLaptop/wofi/default.nix
    ../../../asuraLaptop/ambxst/home.nix
    ../../../asuraLaptop/waybar/default.nix
  ];

  home.packages = with pkgs; [
    wofi
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
