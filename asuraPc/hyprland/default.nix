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
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    plugins = [
      inputs.hyprland-plugins.packages.${system}.hyprexpo
    ];
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "bash -lc 'sleep 1; state_dir=\"\${XDG_STATE_HOME:-$HOME/.local/state}/Ambxst\"; mkdir -p \"$state_dir\"; ambxst >>\"$state_dir/quickshell-launch.log\" 2>&1 &'"
      ];

      monitor = [
        "DP-1,1920x1080@165,0x0,1"
        ",preferred,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "NIXOS_OZONE_WL,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "__EGL_VENDOR_LIBRARY_FILENAMES,/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json"
        "NVD_BACKEND,direct"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
      ];

      cursor = {
        default_monitor = "DP-1";
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

      misc = {
        vfr = true;
        vrr = 1;
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
