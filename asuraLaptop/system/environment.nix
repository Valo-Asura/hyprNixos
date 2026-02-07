# Environment Configuration
{ pkgs, ... }:

{
  environment = {
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland,x11";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      # Accessibility support for keyboard input
      GTK_MODULES = "gail:atk-bridge";
      NO_AT_BRIDGE = "0";
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
      inode/directory=nemo.desktop
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
