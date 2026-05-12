{ inputs, pkgs, ... }: {
  

  wayland.windowManager.hyprland.settings.exec-once =
    [ "systemctl --user start hyprpolkitagent" ];
}
