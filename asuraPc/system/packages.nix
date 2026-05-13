# System Packages Configuration
{ lib, pkgs, inputs, ... }:

{
  environment.systemPackages = (with pkgs; [
    # System Info & Terminal
    microfetch
    zsh
    fish

    # System Tools
    polkit
    udisks2
    udiskie

    # Screenshot and Screen Recording
    grimblast
    hyprshot
    swappy # Screenshot editor

    # Polkit Agent
    inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

    # File Management & NTFS Support
    thunar # Lightweight GTK file manager (replaces nemo + cinnamon-common)
    xarchiver
    gvfs
    ntfs3g
    exfat # Windows filesystem support

    # Desktop Environment
    xdg-utils
    networkmanager
    tuigreet # removed swaylock (using hyprlock)
    xdg-user-dirs # xdg-desktop-portals in services.nix

    # Vibeshell required packages (system-level integration; core deps come from Vibeshell package)
    (writeShellScriptBin "internet-unblock" ''
    '')
    dconf
    gtk3
    gtk4
    adwaita-icon-theme
    gsettings-desktop-schemas
    at-spi2-atk
    at-spi2-core
    libgtop

    # Multimedia
    vlc

    # Hyprland Panel Dependencies
    bluez
    hyprsunset
    hypridle

    # Development
    wget
    git
    jq
    eza
    bat
    fd
    ripgrep
    direnv
    nix-direnv
    nixfmt
    nil
    uv
    inter
    sops
    docker
    docker-compose

    # IDE
    antigravity
    inputs.code-cursor-nix.packages.${pkgs.stdenv.hostPlatform.system}.cursor

    # Terminal enhancements
    btop
    tree
    fzf
    curl
    yq

    # Python Environment
    (python3.withPackages (
      ps: with ps; [
        pip
        requests
      ]
    ))
  ]) ++ lib.optionals (builtins.hasAttr "windsurf" pkgs) [
    pkgs.windsurf
  ];
}
