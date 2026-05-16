{ lib, ... }: {
  wayland.windowManager.hyprland.settings.on = lib.mkAfter [
    {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd("systemctl --user start hyprpolkitagent")
          end
        '')
      ];
    }
  ];
}
