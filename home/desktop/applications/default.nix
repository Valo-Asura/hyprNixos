# Desktop applications
{ pkgs, ... }:

{
  imports = [
    ../../../asuraPc/wofi/default.nix
    ../../../asuraPc/vibeshell/home.nix
  ];

  home.packages = [ pkgs.wofi ];

  xdg.dataFile."applications/org.gnome.Nautilus.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Files
      Comment=Access and organize files
      Exec=env GTK_THEME=Adwaita:dark nautilus --new-window %U
      TryExec=nautilus
      Icon=org.gnome.Nautilus
      Terminal=false
      Type=Application
      DBusActivatable=false
      StartupNotify=true
      Categories=GNOME;GTK;Utility;Core;FileManager;
      MimeType=inode/directory;application/x-gnome-saved-search;
      Actions=new-window;

      [Desktop Action new-window]
      Name=New Window
      Exec=env GTK_THEME=Adwaita:dark nautilus --new-window
    '';
  };

  xdg.dataFile."applications/steam.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Steam
      GenericName=Game launcher
      Comment=Launch Steam with the same capability-clean wrapper used by the terminal
      Exec=/run/current-system/sw/bin/steam-safe %U
      TryExec=/run/current-system/sw/bin/steam-safe
      Icon=steam
      Terminal=false
      Type=Application
      Categories=Network;FileTransfer;Game;
      MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
      StartupWMClass=steam
      PrefersNonDefaultGPU=true
      X-KDE-RunOnDiscreteGpu=true
    '';
  };

  xdg.dataFile."applications/Counter-Strike 2.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Counter-Strike 2
      Comment=Play Counter-Strike 2 on Steam
      Exec=/run/current-system/sw/bin/steam-safe steam://rungameid/730
      Icon=steam_icon_730
      Terminal=false
      Type=Application
      Categories=Game;
      StartupWMClass=cs2
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/steam" = "steam.desktop";
    "x-scheme-handler/steamlink" = "steam.desktop";
  };
}
