# System Packages Configuration
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # System Info & Terminal
    microfetch kitty zsh fish

    # System Tools
    polkit udisks2 udiskie
    lm_sensors brightnessctl dconf

    # Screenshot and Screen Recording
    grim slurp wl-clipboard grimblast hyprshot
    swappy # Screenshot editor

    # Polkit Agent
    inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

    # File Management & NTFS Support
    nemo # Primary file manager
    cinnamon-common # Nemo dependencies
    xarchiver gvfs fzf
    ntfs3g exfat # Windows filesystem support

    # Desktop Environment
    waybar swaybg swww wlogout xdg-utils
    swaylock networkmanager tuigreet
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs

    # GTK and Icon Dependencies for ambxst (minimal set)
    gtk3 gtk4 adwaita-icon-theme hicolor-icon-theme
    gsettings-desktop-schemas glib

    # Input and Accessibility for ambxst
    at-spi2-atk at-spi2-core

    # Multimedia
    playerctl vlc librewolf

    # Hyprland Panel Dependencies
    wireplumber libgtop bluez dart-sass
    upower matugen
    hyprsunset hypridle btop grimblast gpu-screen-recorder

    # Development
    wget git eza bat fd ripgrep direnv nixfmt-classic nil inter
    #ide
    vscode antigravity kiro 
    
    # Terminal enhancements and fun tools
    bottom htop btop tree dialog fzf
    fortune cowsay lolcat figlet
    cmatrix sl toilet boxes neofetch speedtest-cli curl
    jq yq mc ranger

    # Python Environment
    (python311.withPackages (ps: with ps; [
      pip requests
    ]))
  ] ++ [
    # Flake Inputs
    inputs.ambxst.packages.${pkgs.stdenv.hostPlatform.system}.Ambxst
  ];
}
