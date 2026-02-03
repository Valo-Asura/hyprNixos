# Desktop applications
{ inputs, pkgs, ... }:

{
  imports = [
    ../../../asuraLaptop/wofi/default.nix
    ../../../asuraLaptop/ags/ags.nix
  ];

  home.packages = with pkgs; [
    wofi
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}