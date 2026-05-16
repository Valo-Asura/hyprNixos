# Programs Configuration
{ pkgs, ... }:

{
  programs = {
    # Enable direnv system-wide
    direnv.enable = true;

    # Fish shell (detailed config in home-manager)
    fish.enable = true;

    # Hyprland NixOS module is required by upstream docs even when
    # the main configuration lives in Home Manager.
    hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    ssh.startAgent = true;
  };
}
