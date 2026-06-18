# Environment Configuration
{ pkgs, ... }:

let
  playwrightBrowsers = pkgs.playwright-driver.browsers.override {
    withFirefox = false;
    withWebkit = false;
  };
in
{
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      SDL_VIDEODRIVER = "wayland,x11";
      GDK_BACKEND = "wayland,x11";
      GTK_THEME = "Adwaita:dark";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      # NVIDIA EGL — must be set before Hyprland starts
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
      NVD_BACKEND = "direct";
      # Accessibility support for keyboard input
      GTK_MODULES = "gail:atk-bridge";
      NO_AT_BRIDGE = "0";
      PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      NODE_PATH = "${pkgs.playwright-test}/lib/node_modules";
      CHROME_BIN = "${pkgs.google-chrome}/bin/google-chrome-stable";
      CHROME_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
      PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
      ADB_MDNS_AUTO_CONNECT = "adb-tls-connect";
    };

    variables = {
      CMAKE_PREFIX_PATH = "/run/current-system/sw";
      CPATH = "/run/current-system/sw/include";
    };

    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
      "/share/dbus-1"
      "/share/gsettings-schemas"
      "/share/icons"
      "/share/pixmaps"
      "/share/gtk-3.0"
      "/share/gtk-4.0"
    ];

    etc."xdg/mime/defaults.list".text = ''
      [Default Applications]
      inode/directory=org.gnome.Nautilus.desktop
      application/zip=org.kde.ark.desktop
      application/x-zip-compressed=org.kde.ark.desktop
      application/x-7z-compressed=org.kde.ark.desktop
      application/x-rar=org.kde.ark.desktop
      application/vnd.rar=org.kde.ark.desktop
      application/x-tar=org.kde.ark.desktop
      application/x-compressed-tar=org.kde.ark.desktop
      application/x-bzip-compressed-tar=org.kde.ark.desktop
      application/x-bzip2-compressed-tar=org.kde.ark.desktop
      application/x-xz-compressed-tar=org.kde.ark.desktop
      application/x-gzip=org.kde.ark.desktop
      application/gzip=org.kde.ark.desktop
      application/x-bzip2=org.kde.ark.desktop
      application/x-xz=org.kde.ark.desktop
      application/zstd=org.kde.ark.desktop
      application/x-lz4=org.kde.ark.desktop
      application/x-iso9660-image=org.kde.ark.desktop
    '';
  };
}
