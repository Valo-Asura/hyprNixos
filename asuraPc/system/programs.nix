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
      withUWSM = true;
      xwayland.enable = true;
    };

    uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/Hyprland";
    };

    chromium = {
      enable = true;
      extensions = [
        # uBlock Origin for Chromium, Chrome, and Brave policy-managed installs.
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      ];
    };

    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    xfconf.enable = true;

    ssh.startAgent = true;
  };
}
