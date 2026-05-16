# Environment Configuration
{ pkgs, ... }:

{
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland,x11";
      GDK_BACKEND = "wayland,x11";
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
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
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
      inode/directory=thunar.desktop
      application/zip=xarchiver.desktop
      application/x-zip-compressed=xarchiver.desktop
      application/x-7z-compressed=xarchiver.desktop
      application/x-rar=xarchiver.desktop
      application/vnd.rar=xarchiver.desktop
      application/x-tar=xarchiver.desktop
      application/x-compressed-tar=xarchiver.desktop
      application/x-gzip=xarchiver.desktop
      application/gzip=xarchiver.desktop
      application/x-bzip2=xarchiver.desktop
      application/x-xz=xarchiver.desktop
      application/x-iso9660-image=xarchiver.desktop
    '';
  };
}
