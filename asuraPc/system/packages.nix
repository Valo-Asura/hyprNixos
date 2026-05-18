# System Packages Configuration
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  davinciResolveClean = pkgs.symlinkJoin {
    name = "davinci-resolve-clean";
    paths = [ pkgs.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/davinci-resolve"
      makeWrapper ${pkgs.davinci-resolve}/bin/davinci-resolve "$out/bin/davinci-resolve" \
        --unset QML2_IMPORT_PATH \
        --unset QML_IMPORT_PATH \
        --unset NIXPKGS_QT6_QML_IMPORT_PATH \
        --unset QT_PLUGIN_PATH \
        --set QT_QPA_PLATFORM xcb
    '';
  };

  whatsappWeb = pkgs.writeShellScriptBin "whatsapp-web" ''
    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --app=https://web.whatsapp.com \
      --class=whatsapp-web \
      "$@"
  '';

  whatsappWebDesktop = pkgs.makeDesktopItem {
    name = "whatsapp-web";
    desktopName = "WhatsApp";
    genericName = "Messaging";
    comment = "Open WhatsApp Web";
    exec = "whatsapp-web";
    icon = "whatsapp";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    startupWMClass = "whatsapp-web";
  };
in
{
  environment.systemPackages =
    (with pkgs; [
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
      (writeShellScriptBin "internet-unblock" "")
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
      freetube
      kdePackages.kdenlive
      obs-studio
      davinciResolveClean

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
      nixd
      uv
      inter
      sops
      docker
      docker-compose
      nodejs
      playwright
      playwright-driver
      chromium
      mongosh
      mongodb-tools

      # IDE & Editor
      neovim
      vscode
      antigravity
      (pkgs.callPackage ./cursor.nix { })

      # Desktop apps
      whatsappWeb
      whatsappWebDesktop
      mongodb-compass
      telegram-desktop
      ani-cli

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
    ])
    ++ lib.optionals (builtins.hasAttr "windsurf" pkgs) [
      pkgs.windsurf
    ];
}
