# System Packages Configuration
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # System Info & Terminal
    microfetch zsh fish

    # System Tools
    polkit udisks2 udiskie

    # Screenshot and Screen Recording
    grimblast hyprshot
    swappy # Screenshot editor

    # Polkit Agent
    inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

    # File Management & NTFS Support
    nemo # Primary file manager
    cinnamon-common # Nemo dependencies
    xarchiver gvfs
    ntfs3g exfat # Windows filesystem support

    # Desktop Environment
    waybar swaybg swww wlogout xdg-utils
    swaylock networkmanager tuigreet
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs

    # Ambxst required packages (system-level integration; core deps come from Ambxst package)
    dconf
    gtk3 gtk4 adwaita-icon-theme
    gsettings-desktop-schemas
    at-spi2-atk at-spi2-core
    libgtop

    # Multimedia
    vlc librewolf

    # Hyprland Panel Dependencies
    bluez dart-sass
    hyprsunset hypridle

    # Development
    wget git eza bat fd ripgrep direnv nixfmt nil inter
    sops

    # ide
    vscode antigravity kiro lmstudio
    
    # Terminal enhancements and fun tools
    btop tree dialog fzf
    figlet speedtest-cli curl
    yq mc ranger

    # Python Environment
    (python311.withPackages (ps: with ps; [
      pip requests
    ]))
  ];
}
