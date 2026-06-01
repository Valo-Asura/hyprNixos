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

  antigravityWithPlaywright = pkgs.symlinkJoin {
    name = "antigravity-with-playwright";
    paths = [ pkgs.antigravity ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      playwright_browsers="${
        pkgs.playwright-driver.browsers.override {
          withFirefox = false;
          withWebkit = false;
        }
      }"
      rm "$out/bin/antigravity"
      makeWrapper ${pkgs.antigravity}/bin/antigravity "$out/bin/antigravity" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.playwright-test
            pkgs.nodejs
            pkgs.chromium
            pkgs.google-chrome
          ]
        } \
        --prefix NODE_PATH : ${pkgs.playwright-test}/lib/node_modules \
        --set PLAYWRIGHT_BROWSERS_PATH "$playwright_browsers" \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1 \
        --set CHROME_BIN ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_PATH ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_EXECUTABLE ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ${pkgs.google-chrome}/bin/google-chrome-stable
    '';
  };

  adbReset = pkgs.writeShellScriptBin "adb-reset" ''
    set -euo pipefail
    export ADB_MDNS_AUTO_CONNECT="''${ADB_MDNS_AUTO_CONNECT:-adb-tls-connect}"

    ${pkgs.android-tools}/bin/adb kill-server >/dev/null 2>&1 || true
    ${pkgs.android-tools}/bin/adb start-server
    ${pkgs.android-tools}/bin/adb reconnect offline >/dev/null 2>&1 || true
    ${pkgs.android-tools}/bin/adb reconnect >/dev/null 2>&1 || true
    ${pkgs.android-tools}/bin/adb devices -l
  '';

  adbWifiConnect = pkgs.writeShellScriptBin "adb-wifi-connect" ''
    set -euo pipefail
    export ADB_MDNS_AUTO_CONNECT="''${ADB_MDNS_AUTO_CONNECT:-adb-tls-connect}"

    if [ "$#" -lt 1 ]; then
      printf '%s\n' \
        'Usage:' \
        '  adb-wifi-connect PHONE_IP:CONNECT_PORT' \
        "" \
        'After pairing in Android Wireless debugging, use the separate "IP address & Port"' \
        'connect port, not the pairing-code port.' >&2
      exit 2
    fi

    ${pkgs.android-tools}/bin/adb start-server
    ${pkgs.android-tools}/bin/adb disconnect "$1" >/dev/null 2>&1 || true
    ${pkgs.android-tools}/bin/adb connect "$1"
    ${pkgs.android-tools}/bin/adb devices -l
  '';

  mysqlLocalInfo = pkgs.writeShellScriptBin "mysql-local-info" ''
    cat <<'EOF'
    MySQL local service
      service: systemctl status mysql
      cli:     mysql -u asura asura_dev
      shell:   mysqlsh --sql asura@localhost:3306
      gui:     mysql-workbench

    Paths
      config:  /etc/my.cnf
      data:    /var/lib/mysql
      socket:  /run/mysqld/mysqld.sock
      binary:  /run/current-system/sw/bin/mysql
    EOF
  '';

  vimWrapped = pkgs.vim-full.customize {
    name = "vim";
    vimrcConfig.customRC = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      syntax on
    '';
  };

  hyprmod = pkgs.callPackage ./hyprmod.nix { };
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
      alsa-utils
      pavucontrol
      pulseaudio
      pwvucontrol
      v4l-utils

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
      playwright-test
      playwright-driver
      chromium
      android-tools # adb / fastboot; udev access is handled by systemd uaccess
      adbReset
      adbWifiConnect
      scrcpy # Android screen/control over adb
      mysql-shell
      mysql-workbench
      mysqlLocalInfo
      mongosh
      mongodb-tools

      # IDE & Editor
      neovim
      vscode
      antigravityWithPlaywright
      (pkgs.callPackage ./cursor.nix { })
      zed-editor
      vimWrapped
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Hyprland Tools
      hyprmod
      hyprsysteminfo
      hyprshutdown

      # Desktop apps
      whatsappWeb
      whatsappWebDesktop
      piper # Linux GUI for Logitech G304/G305 DPI and button profiles
      solaar # Logitech receiver and wireless device manager
      simple-mtpfs
      jmtpfs
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
