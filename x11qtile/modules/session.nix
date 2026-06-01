# session.nix
# Isolated display manager and session configuration for X11 Qtile
{
  config,
  pkgs,
  lib,
  ...
}:

let
  qtileConfig = ../config/qtile;
  xorgConfig = pkgs.writeText "x11qtile-xorg.conf" config.services.xserver.config;
  xorgModulePath = lib.concatStringsSep "," (
    map (module: "${module}/lib/xorg/modules") config.services.xserver.modules
  );

  xsessionWrapper = pkgs.writeShellScriptBin "start-x11qtile-xserver" ''
    set -uo pipefail

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
    mkdir -p "$state_dir"
    log_file="$state_dir/xserver.log"
    exec >>"$log_file" 2>&1

    echo "---- x11qtile xserver wrapper: $(date -Is) ----"
    echo "session command: $*"

    display=""
    for candidate in 1 2 3 4 5; do
      lock="/tmp/.X''${candidate}-lock"
      socket="/tmp/.X11-unix/X''${candidate}"

      if [ -r "$lock" ]; then
        lock_pid="$(tr -cd '0-9' < "$lock" || true)"
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
          echo "display :$candidate is active by pid $lock_pid"
          continue
        fi
        echo "removing stale X lock for :$candidate"
        rm -f "$lock" "$socket" 2>/dev/null || true
      elif [ -S "$socket" ]; then
        echo "removing stale X socket for :$candidate"
        rm -f "$socket" 2>/dev/null || true
      fi

      if [ ! -e "$lock" ] && [ ! -S "$socket" ]; then
        display="$candidate"
        break
      fi
    done

    if [ -z "$display" ]; then
      echo "no free X display found"
      exit 1
    fi

    if [ "$#" -eq 0 ]; then
      set -- ${qtileStart}/bin/start-x11qtile
    fi

    echo "starting Xorg on :$display with NixOS Xorg config"
    exec ${pkgs.xinit}/bin/startx "$@" -- ":$display" \
      -config ${xorgConfig} \
      -modulepath ${lib.escapeShellArg xorgModulePath} \
      -nolisten tcp
  '';

  qtileStart = pkgs.writeShellScriptBin "start-x11qtile" ''
    set -uo pipefail

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/x11qtile"
    mkdir -p "$state_dir"
    log_file="$state_dir/session.log"
    exec >>"$log_file" 2>&1

    echo "---- x11qtile session start: $(date -Is) ----"

    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=Qtile
    export XDG_SESSION_DESKTOP=Qtile
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    export NIXOS_OZONE_WL=0

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment --systemd \
        DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
        GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL
    fi

    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user import-environment \
        DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
        GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL || true
    fi

    user_config="$HOME/.config/x11qtile/qtile/config.py"
    store_config="${qtileConfig}/config.py"
    config_file="$user_config"

    if [ ! -r "$config_file" ]; then
      echo "user config missing: $config_file"
      config_file="$store_config"
    fi

    if ! ${pkgs.python3Packages.qtile}/bin/qtile check -c "$config_file"; then
      echo "qtile check failed for $config_file"
      if [ "$config_file" != "$store_config" ] && ${pkgs.python3Packages.qtile}/bin/qtile check -c "$store_config"; then
        echo "falling back to store config: $store_config"
        config_file="$store_config"
      else
        echo "store config also failed; starting qtile default config"
        exec ${pkgs.python3Packages.qtile}/bin/qtile start -b x11
      fi
    fi

    export X11QTILE_CONFIG_DIR="$(dirname "$config_file")"
    echo "starting qtile with config: $config_file"
    exec ${pkgs.python3Packages.qtile}/bin/qtile start \
      -b x11 \
      -c "$config_file"
  '';

  # Declaratively define desktop session files in the Nix store
  hyprlandSession = pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
    [Desktop Entry]
    Name=Hyprland (Wayland)
    Comment=An intelligent dynamic tiling Wayland compositor
    Exec=${config.programs.hyprland.package}/bin/start-hyprland
    Type=Application
  '';

  qtileSession = pkgs.writeTextDir "share/xsessions/qtile.desktop" ''
    [Desktop Entry]
    Name=Qtile (X11)
    Comment=Qtile Tiling Window Manager
    Exec=${qtileStart}/bin/start-x11qtile
    Type=Application
  '';

  tuigreetCommand =
    "${pkgs.tuigreet}/bin/tuigreet "
    + "--remember "
    + "--sessions ${hyprlandSession}/share/wayland-sessions "
    + "--xsessions ${qtileSession}/share/xsessions "
    + "--xsession-wrapper ${xsessionWrapper}/bin/start-x11qtile-xserver "
    + "--asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' "
    + "--cmd ${config.programs.hyprland.package}/bin/start-hyprland";
in
{
  # Add session selection while preserving Hyprland as the default command.
  services.greetd.settings.default_session.command = lib.mkOverride 90 tuigreetCommand;

  # Preserve the existing OpenSSH agent from programs.ssh.startAgent.
  services.gnome.gcr-ssh-agent.enable = false;
}
