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
  xdman = pkgs.callPackage ./xdman.nix { };
  xdmParkWindow = pkgs.writeShellScript "xdm-park-window" ''
    set -euo pipefail

    for _ in $(${pkgs.coreutils}/bin/seq 1 40); do
      addr="$(${pkgs.hyprland}/bin/hyprctl clients -j 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "xdm-app") | .address' \
        | ${pkgs.coreutils}/bin/head -n1 || true)"

      if [ -n "$addr" ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null 2>&1 || true
        ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:xdm", silent = true })' >/dev/null 2>&1 || true
        exit 0
      fi

      ${pkgs.coreutils}/bin/sleep 0.25
    done
  '';
  xdmOpen = pkgs.writeShellScriptBin "xdm-open" ''
    set -euo pipefail

    if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f '/xdm-app( |$)' >/dev/null 2>&1; then
      if [ "$#" -eq 0 ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.workspace.toggle_special("xdm")' >/dev/null 2>&1 || true
        exit 0
      fi
    fi

    exec ${xdman}/bin/xdman "$@"
  '';
  xdmOpenDesktop = pkgs.makeDesktopItem {
    name = "xdm-open";
    desktopName = "Xtreme Download Manager";
    genericName = "Download Manager";
    comment = "Open Xtreme Download Manager or pass browser links to it";
    exec = "xdm-open %U";
    icon = "xdm-logo";
    categories = [
      "Network"
      "FileTransfer"
      "GTK"
    ];
    mimeTypes = [
      "application/xdm-app"
      "x-scheme-handler/xdm-app"
      "x-scheme-handler/xdm+app"
    ];
    startupNotify = false;
  };
in
{
  environment.systemPackages =
    (with pkgs; [
      xdman
      xdmOpen
      xdmOpenDesktop
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
      kdePackages.ark
      nautilus
      gnome-disk-utility
      pcmanfm-qt
      gvfs
      ntfs3g
      exfat # Windows filesystem support

      # Desktop Environment
      xdg-utils
      networkmanager
      tuigreet # removed swaylock (using hyprlock)
      xdg-user-dirs # xdg-desktop-portals in services.nix

      # Desktop shell support and rollback helpers.
      (writeShellScriptBin "internet-unblock" "")
      dconf
      gtk3
      gtk4
      adw-gtk3
      adwaita-icon-theme
      hicolor-icon-theme
      papirus-icon-theme
      kdePackages.breeze-icons
      gsettings-desktop-schemas
      at-spi2-atk
      at-spi2-core
      libgtop
      loupe
      kdePackages.okular
      sushi

      # Multimedia
      mpv
      vlc
      easyeffects
      freetube
      kdePackages.kdenlive
      obs-studio
      davinciResolveClean
      alsa-utils
      pavucontrol
      pulseaudio
      pwvucontrol
      easyeffects
      v4l-utils

      # Hyprland Panel Dependencies
      bluez
      hyprsunset
      hypridle
      wl-clipboard
      cliphist
      libnotify
      hyprpicker
      wf-recorder
      cava
      matugen
      mpvpaper
      songrec
      zenity
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
      nwg-look

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

  systemd.tmpfiles.rules = [
    "L+ /opt/xdman - - - - ${xdman}"
  ];

  systemd.user.services.xdman = {
    description = "Xtreme Download Manager browser and video capture bridge";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
    serviceConfig = {
      ExecStart = "${xdman}/bin/xdman";
      ExecStartPost = "${xdmParkWindow}";
      Restart = "on-failure";
      RestartSec = 15;
      Environment = [
        "GTK_USE_PORTAL=1"
        "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
      ];
    };
  };
}
