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

  # Startup wrapper: shows a splash logo, launches vibeshell, then removes the
  # temporary background once Quickshell is detected.
  vibeshellStart = pkgs.writeShellScriptBin "vibeshell-start" ''
    # Show splash background via swaybg while Quickshell loads
    ${pkgs.swaybg}/bin/swaybg -i ${../assets/vibeshell-loading.svg} -m fill &
    SWAYBG_PID=$!

    # Start vibeshell (the launcher script from the Vibeshell package)
    vibeshell start &

    # Wait until Quickshell process appears, then remove the splash
    for i in $(seq 1 30); do
      sleep 1
      if ${pkgs.procps}/bin/pgrep -x qs > /dev/null 2>&1; then
        break
      fi
    done
    kill "$SWAYBG_PID" 2>/dev/null || true
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
    plugins = [ ];
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
