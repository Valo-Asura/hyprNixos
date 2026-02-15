# good enough tiling manager
{ pkgs, config, inputs, lib, ... }:
let
  border-size = 1;
  gaps-in = 2;
  gaps-out = 6;
  active-opacity = 1;
  inactive-opacity = 0.89;
  rounding = 8;
  blur = true;
  keyboardLayout = "us";
  border-color= "rgb(b4befe)";
in {

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
    plugins = [
      pkgs.hyprlandPlugins.hyprexpo
    ];
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "code"
        "ambxst"
        "bash -lc 'sleep 6; mpvpaper -o \"no-audio --loop --hwdec=auto\" eDP-1 /home/asura/Downloads/wall1.mp4'"
      ];

      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
        "DP-7,disable"
        "DP-8,disable"
        "DP-9,disable"
        "HDMI-A-1,preferred,auto,1"
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
        "WLR_NO_HARDWARE_CURSORS,1"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
      ];

      cursor = {
        no_hardware_cursors = true;
        default_monitor = "eDP-1";
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
        direct_scanout = true;    # bypass compositor for fullscreen apps
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

  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
