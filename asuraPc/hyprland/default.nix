# good enough tiling manager
{
  pkgs,
  config,
  inputs,
  system,
  lib,
  ...
}:
let
  border-size = 1;
  gaps-in = 2;
  gaps-out = 6;
  active-opacity = 1;
  inactive-opacity = 1;
  rounding = 6;
  blur = false;
  keyboardLayout = "us";
  border-color = "rgb(b4befe)";
  primaryMonitor = "DP-1";
  primaryMonitorDesc = "Guangxi Century Innovation Display Electronics Co. Ltd 24FHDMIQII2G 0000000000001";
  primaryMode = "1920x1080@165";
  loadingLogo = pkgs.runCommand "vibeshell-loading-logo.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
    rsvg-convert -w 512 -h 512 ${../assets/vibeshell-loading.svg} -o "$out"
  '';
  vibeshellStart = pkgs.writeShellScriptBin "vibeshell-start" ''
    set -euo pipefail

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/Vibeshell"
    mkdir -p "$state_dir"

    loader_pid=""
    cleanup_loader() {
      if [ -n "$loader_pid" ] && kill -0 "$loader_pid" 2>/dev/null; then
        kill "$loader_pid" 2>/dev/null || true
      fi
    }

    trap cleanup_loader EXIT

    ${pkgs.swaybg}/bin/swaybg -c "#0b0f14" -i "${loadingLogo}" -m center >/dev/null 2>&1 &
    loader_pid="$!"

    if ! command -v vibeshell >/dev/null 2>&1; then
      echo "vibeshell command not found" >>"$state_dir/quickshell-launch.log"
      exit 127
    fi

    vibeshell >>"$state_dir/quickshell-launch.log" 2>&1 &
    shell_pid="$!"

    for _ in $(${pkgs.coreutils}/bin/seq 1 120); do
      if ! kill -0 "$shell_pid" 2>/dev/null; then
        break
      fi
      if ${pkgs.procps}/bin/pgrep -f '/(qs|quickshell).*shell.qml' >/dev/null 2>&1; then
        ${pkgs.coreutils}/bin/sleep 0.8
        cleanup_loader
        loader_pid=""
        break
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    cleanup_loader
    loader_pid=""
    wait "$shell_pid"
  '';
in
{

  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./wallpaper-manager.nix
    ./lock-wallpaper-sync.nix
  ];

  home.packages = with pkgs; [
    qt6.qtwayland
    brightnessctl
    libva
    wayland-utils
    inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default
    vibeshellStart
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Reuse the package pair from the NixOS module so Hyprland and XDPH stay in sync.
    package = null;
    portalPackage = null;
    plugins = [
      inputs.hyprland-plugins.packages.${system}.hyprexpo
    ];
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP LANG LC_CTYPE LC_TIME LC_MONETARY LC_NUMERIC LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION"
        "${vibeshellStart}/bin/vibeshell-start"
      ];

      monitor = [
        "desc:${primaryMonitorDesc},${primaryMode},0x0,1"
        "${primaryMonitor},${primaryMode},0x0,1"
        ",preferred,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "LANG,en_IN"
        "MOZ_ENABLE_WAYLAND,1"
        "NIXOS_OZONE_WL,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "__EGL_VENDOR_LIBRARY_FILENAMES,/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json"
        "NVD_BACKEND,direct"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
      ];

      cursor = {
        default_monitor = primaryMonitor;
        no_hardware_cursors = true;
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;

        layout = "master";
        "col.active_border" = border-color;
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;

        shadow = {
          enabled = false;
        };

        blur = {
          enabled = blur;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
      };

      master = {
        new_status = "master";
        allow_small_split = true;
        mfact = 0.5;
      };

      debug = {
        vfr = true;
      };

      misc = {
        vrr = 1;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        focus_on_activate = true;
        enable_swallow = false;
        swallow_regex = "";
      };

      render = {
        direct_scanout = false; # disabled: causes crashes with NVIDIA on Wayland
      };

      windowrule = [
        "match:tag modal, float = true"
        "match:tag modal, pin = true"
        "match:tag modal, center = true"
      ];

      layerrule = [
        "no_anim on, match:namespace launcher"
        "no_anim on, match:namespace ^ags-.*$"
      ];

      input = {
        kb_layout = keyboardLayout;
        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = true;
          tap_button_map = "lrm";
          clickfinger_behavior = false;
        };
      };

      gesture = [
        "3, horizontal, workspace"
      ];

    };
  };

  services.hyprpaper.enable = false;

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
