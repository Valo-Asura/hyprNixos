# Programs Configuration
{ pkgs, ... }:

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

    # Track the Hyprland package pair from the pinned nixpkgs input instead of
    # hardcoding an upstream release tag in this flake.
    hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
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
