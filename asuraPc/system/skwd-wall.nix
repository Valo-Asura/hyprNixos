# Declarative skwd-wall integration.
{
  inputs,
  pkgs,
  ...
}:

let
  configFormat = pkgs.formats.json { };
  wallpaperDir = "/home/asura/Pictures/wallpaper";
  skwdWallConfig = {
    compositor = "hyprland";
    monitor = "";

    general = {
      locale = "";
      closeOnSelection = false;
      reopenAtLastSelection = true;
      notifyOnWallpaperChange = true;
    };

    paths = {
      wallpaper = wallpaperDir;
      videoWallpaper = wallpaperDir;
      cache = "";
      templates = "";
      scripts = "";
      steam = "";
      steamWorkshop = "";
      steamWeAssets = "";
    };

    features = {
      matugen = true;
      ollama = false;
      steam = false;
      wallhaven = false;
      videoPreview = true;
    };

    colorSource = "magick";

    matugen = {
      schemeType = "scheme-fidelity";
      mode = "dark";
    };

    integrations = [
      {
        name = "skwd-wall";
        template = "quickshell-colors.json";
        output = "colors.json";
      }
      {
        name = "skwd";
        template = "quickshell-colors.json";
        output = "~/.cache/skwd/colors.json";
      }
      {
        name = "kitty";
        template = "kitty.conf";
        output = "~/.config/kitty/skwd-theme.conf";
        reload = "pkill -USR1 kitty";
      }
      {
        name = "ghostty";
        template = "ghostty.conf";
        output = "~/.config/ghostty/skwd-theme";
        reload = "pkill -USR2 ghostty";
      }
      {
        name = "vscode";
        template = "vscode-theme.json";
        output = "~/.vscode/extensions/matugen.matugen-theme-1.0.0/themes/matugen-color-theme.json";
      }
      {
        name = "vesktop";
        template = "vesktop.css";
        output = "~/.config/vesktop/themes/kitty-match.css";
      }
      {
        name = "yazi";
        template = "yazi-theme.toml";
        output = "~/.config/yazi/theme.toml";
      }
      {
        name = "qt6ct";
        template = "qt6ct-colors.conf";
        output = "~/.config/qt6ct/colors/matugen.conf";
      }
    ];

    components.wallpaperSelector = {
      displayMode = "slices";
      sliceSpacing = -30;
      hexScrollStep = 1;
      customPresets = { };
    };

    paper.engine = "skwd-paper";
    wallpaperMute = true;
    pickOnlyMode = false;
    restoreOnStartup = true;
    externalWallpaperCommand = "";
    postProcessing = [ ];

    performance = {
      imageOptimizePreset = "balanced";
      imageOptimizeResolution = "2k";
      videoConvertPreset = "balanced";
      videoConvertResolution = "2k";
      autoOptimizeImages = false;
      autoConvertVideos = false;
      imageTrashDays = 7;
      videoTrashDays = 7;
      autoDeleteImageTrash = false;
      autoDeleteVideoTrash = false;
    };
  };
in
{
  imports = [
    inputs.skwd-wall.nixosModules.default
  ];

  programs.skwd-wall.enable = true;

  # The upstream module installs the wrapped package and user unit. Enable the
  # daemon for both generic graphical sessions and the Hyprland HM target.
  systemd.user.services.skwd-daemon.wantedBy = [
    "graphical-session.target"
    "hyprland-session.target"
  ];

  home-manager.users.asura.xdg.configFile."skwd-wall/config.json".source =
    configFormat.generate "skwd-wall-config.json" skwdWallConfig;
}
