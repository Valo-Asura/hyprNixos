{ inputs, pkgs, ... }:
{
  # add the home manager module
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;

    # symlink to ~/.config/ags
    # configDir = ../ags;

    # additional packages to add to gjs's runtime
    extraPackages = with pkgs; [
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.battery
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.mpris
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.network
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.tray
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.wireplumber
      fzf
    ];
  };
}