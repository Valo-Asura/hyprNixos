# Programs Configuration
{ inputs, pkgs, ... }:

{
  programs = {
    # Enable direnv system-wide
    direnv.enable = true;

    # Fish shell (detailed config in home-manager)
    fish.enable = true;

    # Zed downloads ACP agents such as codex-acp as generic Linux binaries.
    # nix-ld provides the dynamic loader path those binaries expect on NixOS.
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        curl
        libxcrypt
      ];
    };

    # Hyprland NixOS module is required by upstream docs even when
    # the main configuration lives in Home Manager.
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    chromium = {
      enable = true;
      extensions = [
        # uBlock Origin for Chromium, Chrome, and Brave policy-managed installs.
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      ];
    };

    ssh.startAgent = true;
  };
}
