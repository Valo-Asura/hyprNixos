{ inputs, pkgs, ... }:

let
  # Toggle Switch: set to true to test vibeshellREzero (C++ native rewrite)
  # or false to keep using the standard Vibeshell (Quickshell/QML)
  useREzero = false;

  vibeshellREzeroPkg = pkgs.callPackage ../vibeshellREzero/package.nix { };

  vibeshellSafeLock = pkgs.writeShellScriptBin "vibeshell-safe-lock" ''
    set -euo pipefail

    if command -v vibeshell >/dev/null 2>&1; then
      if vibeshell lock; then
        exit 0
      fi
      echo "vibeshell lock failed, falling back to hyprlock" >&2
    fi

    if ${pkgs.procps}/bin/pgrep -x hyprlock >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pkgs.hyprlock}/bin/hyprlock
  '';

  vibeshellLockBeforeSleep = pkgs.writeShellScriptBin "vibeshell-lock-before-sleep" ''
    set -euo pipefail

    ${vibeshellSafeLock}/bin/vibeshell-safe-lock
    sleep 1
  '';

  shellSwitcher = pkgs.writeShellScriptBin "switch-shell" ''
    set -euo pipefail

    state_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/asura-shell"
    state_file="$state_dir/current-shell"
    nandriod_shell="/home/asura/Downloads/test/asura-quickshell-main/shell.qml"
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/asura-shell"

    usage() {
      printf '%s\n' \
        "Usage: switch-shell <vibeshell|nandriod>" \
        "" \
        "Stops the current managed Quickshell instance and starts the selected shell."
    }

    stop_managed_shells() {
      if command -v vibeshell >/dev/null 2>&1; then
        vibeshell quit >/dev/null 2>&1 || true
      fi

      ${pkgs.procps}/bin/pkill -f 'quickshell.*asura-quickshell-main/shell.qml' >/dev/null 2>&1 || true
      ${pkgs.procps}/bin/pkill -f 'qs .*asura-quickshell-main/shell.qml' >/dev/null 2>&1 || true
    }

    start_vibeshell() {
      ${pkgs.coreutils}/bin/mkdir -p "$state_dir" "$log_dir"
      stop_managed_shells
      printf '%s\n' "vibeshell" > "$state_file"
      ${pkgs.coreutils}/bin/nohup vibeshell > "$log_dir/vibeshell.log" 2>&1 &
      printf 'Started VibeShell\n'
    }

    start_nandriod() {
      if [ ! -f "$nandriod_shell" ]; then
        printf 'Nandriod shell not found: %s\n' "$nandriod_shell" >&2
        exit 1
      fi

      qs_bin="$(command -v qs || command -v quickshell || true)"
      if [ -z "$qs_bin" ]; then
        printf 'Could not find qs/quickshell in PATH\n' >&2
        exit 1
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$state_dir" "$log_dir"
      stop_managed_shells
      printf '%s\n' "nandriod" > "$state_file"
      export XDG_DATA_DIRS="${pkgs.material-symbols}/share:${pkgs.google-fonts}/share:${pkgs.papirus-icon-theme}/share:${pkgs.adwaita-icon-theme}/share:${pkgs.hicolor-icon-theme}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
      export QML2_IMPORT_PATH="${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml:''${QML2_IMPORT_PATH:-}"
      export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
      export QT_QPA_PLATFORMTHEME=qt6ct
      export GTK_THEME=adw-gtk3-dark
      export QS_ICON_THEME=Papirus-Dark
      QS_APP_ID="nandriod-shell" ${pkgs.coreutils}/bin/nohup "$qs_bin" -p "$nandriod_shell" > "$log_dir/nandriod.log" 2>&1 &
      printf 'Started Nandriod shell\n'
    }

    if [ "$#" -ne 1 ]; then
      usage >&2
      exit 2
    fi

    case "$1" in
      vibeshell) start_vibeshell ;;
      nandriod) start_nandriod ;;
      -h|--help|help) usage ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
  '';
in
{
  imports = [ inputs.vibeshell.nixosModules.default ];

  programs.vibeshell = {
    enable = !useREzero;
    package = inputs.vibeshell.packages.${pkgs.stdenv.hostPlatform.system}.Vibeshell;
    fonts.enable = true;
  };

  environment.systemPackages = [
    vibeshellSafeLock
    vibeshellLockBeforeSleep
    shellSwitcher
    pkgs.dgop
    pkgs.material-symbols
    pkgs.google-fonts
    pkgs.papirus-icon-theme
    pkgs.hicolor-icon-theme
    pkgs.qt6Packages.qt5compat
  ]
  ++ (if useREzero then [ vibeshellREzeroPkg ] else [ ]);

  systemd.tmpfiles.rules = [
    # Nandriod reference shell calls /usr/bin/dgop directly.
    "L+ /usr/bin/dgop - - - - ${pkgs.dgop}/bin/dgop"
    "d /home/asura/.cache/nandoroid 0755 asura users -"
  ];
}
