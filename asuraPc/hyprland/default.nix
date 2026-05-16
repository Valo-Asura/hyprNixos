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

    # Start vibeshell (no subcommand = launch; cli.sh's "" case handles startup)
    vibeshell &

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
    configType = "lua";
    # Reuse the package pair from the NixOS module so Hyprland and XDPH stay in sync.
    package = null;
    portalPackage = null;
    plugins = [ ];
    xwayland.enable = true;
    settings = {
      monitor = [
        {
          output = "desc:${primaryMonitorDesc}";
          mode = primaryMode;
          position = "0x0";
          scale = "1";
        }
        {
          output = primaryMonitor;
          mode = primaryMode;
          position = "0x0";
          scale = "1";
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "1";
        }
      ];

      env = [
        {
          _args = [
            "XDG_SESSION_TYPE"
            "wayland"
          ];
        }
        {
          _args = [
            "XDG_CURRENT_DESKTOP"
            "Hyprland"
          ];
        }
        {
          _args = [
            "XDG_SESSION_DESKTOP"
            "Hyprland"
          ];
        }
        {
          _args = [
            "LANG"
            "en_IN"
          ];
        }
        {
          _args = [
            "MOZ_ENABLE_WAYLAND"
            "1"
          ];
        }
        {
          _args = [
            "NIXOS_OZONE_WL"
            "1"
          ];
        }
        {
          _args = [
            "QT_QPA_PLATFORM"
            "wayland;xcb"
          ];
        }
        {
          _args = [
            "QT_WAYLAND_DISABLE_WINDOWDECORATION"
            "1"
          ];
        }
        {
          _args = [
            "ELECTRON_OZONE_PLATFORM_HINT"
            "auto"
          ];
        }
        {
          _args = [
            "__GL_GSYNC_ALLOWED"
            "0"
          ];
        }
        {
          _args = [
            "__GL_VRR_ALLOWED"
            "0"
          ];
        }
        {
          _args = [
            "LIBVA_DRIVER_NAME"
            "nvidia"
          ];
        }
        {
          _args = [
            "GBM_BACKEND"
            "nvidia-drm"
          ];
        }
        {
          _args = [
            "__GLX_VENDOR_LIBRARY_NAME"
            "nvidia"
          ];
        }
        {
          _args = [
            "__EGL_VENDOR_LIBRARY_FILENAMES"
            "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json"
          ];
        }
        {
          _args = [
            "NVD_BACKEND"
            "direct"
          ];
        }
        {
          _args = [
            "SDL_VIDEODRIVER"
            "wayland,x11"
          ];
        }
        {
          _args = [
            "CLUTTER_BACKEND"
            "wayland"
          ];
        }
        {
          _args = [
            "XCURSOR_SIZE"
            "24"
          ];
        }
        {
          _args = [
            "XCURSOR_THEME"
            "Bibata-Modern-Classic"
          ];
        }
      ];

      on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP LANG LC_CTYPE LC_TIME LC_MONETARY LC_NUMERIC LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION")
                hl.exec_cmd("${vibeshellStart}/bin/vibeshell-start")
              end
            '')
          ];
        }
      ];

      config = {
        cursor = {
          default_monitor = primaryMonitor;
          no_hardware_cursors = 1;
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
          # Disabled: direct scanout has been unstable with NVIDIA.
          direct_scanout = 0;
        };

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
      };

      window_rule = [
        {
          match.title = "^(.*(Open File|Choose Files|File Upload|Save As|Library).*)$";
          float = true;
          center = true;
          size = [
            900
            600
          ];
        }
        {
          match.title = "^(.*(Authentication Required|PolicyKit1).*)$";
          float = true;
          center = true;
          size = [
            500
            400
          ];
        }
        {
          match.class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$";
          float = true;
          center = true;
          size = [
            500
            400
          ];
        }
        {
          match.class = "^(file-roller|org.gnome.FileRoller)$";
          float = true;
          center = true;
          size = [
            800
            600
          ];
        }
        {
          match.class = "^(xdg-desktop-portal-.*)$";
          float = true;
          center = true;
          size = [
            900
            600
          ];
        }
      ];

      layer_rule = [
        {
          match.namespace = "launcher";
          no_anim = true;
        }
        {
          match.namespace = "^ags-.*$";
          no_anim = true;
        }
      ];

      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
      ];
    };
  };

  services.hyprpaper.enable = false;

  # Prevent Hyprland from creating a stale autogenerated hyprland.conf on boot
  # that shadows the home-manager-managed hyprland.lua.
  # We place a managed hyprland.conf that simply sources the lua config so
  # Hyprland always loads our real settings regardless of startup order.
  xdg.configFile."hypr/hyprland.conf" = {
    force = true;
    text = ''# Managed by home-manager — do not edit.
# Real config is in hyprland.lua (configType = "lua").
# This file exists only so Hyprland does not regenerate an autogenerated
# placeholder that would shadow hyprland.lua.
source = ~/.config/hypr/hyprland.lua
'';
  };

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
