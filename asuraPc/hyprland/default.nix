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
  gaps-out = {
    top = 0;
    bottom = 6;
    left = 2;
    right = 2;
  };
  active-opacity = 1;
  inactive-opacity = 1;
  rounding = 6;
  blur = false;
  keyboardLayout = "us";
  border-color = "rgb(b4befe)";
  primaryMonitor = "HDMI-A-1";
  primaryMonitorDesc = "AOC 24G1WG4 0x000000A1";
  primaryMode = "1920x1080@144";

  # Startup wrapper: shows a splash logo, stops inactive shell stacks, launches
  # Quickshell VibeShell, then removes the temporary background once it maps.
  vibeshellStart = pkgs.writeShellScriptBin "vibeshell-start" ''
    set -euo pipefail

    # Show splash background via swaybg while VibeShell maps its layers.
    ${pkgs.swaybg}/bin/swaybg -i ${../assets/vibeshell-loading.svg} -m fill &
    SWAYBG_PID=$!

    cleanup() {
      kill "$SWAYBG_PID" 2>/dev/null || true
    }
    trap cleanup EXIT

    # Prevent inactive shell/wallpaper stacks from stacking with VibeShell.
    ${pkgs.systemd}/bin/systemctl --user stop --no-block \
      noctalia.service \
      noctalia-shell.service \
      skwd-daemon.service \
      vibeshellREzero-live.service 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x noctalia 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x skwd-daemon 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x skwd-paper 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x skwd-paper-still 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x vibeshellREzero 2>/dev/null || true

    /run/current-system/sw/bin/vibeshell &
    SHELL_PID=$!

    for i in $(seq 1 30); do
      if ${pkgs.procps}/bin/pgrep -f 'vibeshell-shell.*shell.qml' >/dev/null 2>&1 || ${pkgs.procps}/bin/pgrep -x 'vibeshellREzero' >/dev/null 2>&1 || ! kill -0 "$SHELL_PID" 2>/dev/null; then
        break
      fi
      sleep 0.2
    done

    cleanup
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
                local f = io.open(os.getenv("HOME") .. "/.config/hypr/hyprland-gui.conf", "r")
                if f ~= nil then
                  io.close(f)
                  hl.exec_cmd("hyprctl source " .. os.getenv("HOME") .. "/.config/hypr/hyprland-gui.conf")
                end
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
          # AOC 24G1WG4 advertises Adaptive-Sync/FreeSync, but desktop VRR can
          # flicker with transparent layer-shell panels on NVIDIA.
          vrr = 0;
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
          match.class = "^(org\\.kde\\.ark|ark|file-roller|org\\.gnome\\.FileRoller|xarchiver)$";
          float = true;
          center = true;
          size = [
            860
            620
          ];
        }
        {
          match.class = "^(org\\.gnome\\.Loupe|loupe|org\\.kde\\.gwenview|Gwenview)$";
          float = true;
          center = true;
          size = [
            980
            720
          ];
        }
        {
          match.class = "^(org\\.gnome\\.NautilusPreviewer|sushi)$";
          float = true;
          center = true;
          size = [
            900
            640
          ];
        }
        {
          match.class = "^(asura-system-monitor|io\\.missioncenter\\.MissionCenter)$";
          float = true;
          center = true;
          size = [
            980
            720
          ];
        }
        {
          match.class = "^(asura-display-manager|hyprmod|nwg-displays|wdisplays)$";
          float = true;
          center = true;
          size = [
            1040
            720
          ];
        }
        {
          match.class = "^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$";
          float = true;
          center = true;
          size = [
            760
            940
          ];
          suppress_event = "maximize";
        }
        {
          match.title = "^(Cloudflare Warp|Warp Taskbar|Warp)$";
          float = true;
          center = true;
          size = [
            760
            940
          ];
          suppress_event = "maximize";
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
        {
          match.class = "^(cs2|steam_app_730)$";
          fullscreen = true;
        }
        {
          match.class = "^(Thunar|thunar)$";
          match.title = "^(File Operation Progress|Confirm to replace files|.*Progress.*)$";
          float = true;
          center = true;
        }
        {
          match.class = "^(org.gnome.Nautilus|nautilus)$";
          match.title = "^(File Operation Progress|Confirm to replace files|.*Progress.*)$";
          float = true;
          center = true;
        }
      ];

      layer_rule = [
        {
          match.namespace = "quickshell:.*";
          blur = false;
          ignore_alpha = 0.79;
        }
        {
          match.namespace = "notifications";
          blur = false;
          ignore_alpha = 0.69;
        }
        {
          match.namespace = "launcher";
          no_anim = true;
          blur = false;
          ignore_alpha = 0.5;
        }
        {
          match.namespace = "overview";
          no_anim = true;
        }
        {
          match.namespace = "session";
          blur = false;
        }
        {
          match.namespace = "quickshell:regionSelector";
          no_anim = true;
          blur = false;
        }
        {
          match.namespace = "quickshell:recordingMarker";
          no_anim = true;
          blur = false;
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

  # Hyprland 0.55 reads hyprland.lua directly. Remove only the old
  # autogenerated fallback if an older generation created it earlier.
  home.activation.removeAutogeneratedHyprlandConf = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    legacy_conf="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$legacy_conf" ] && ${pkgs.gnugrep}/bin/grep -q '^autogenerated = 1' "$legacy_conf"; then
      ${pkgs.coreutils}/bin/rm -f "$legacy_conf"
    fi
  '';

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
