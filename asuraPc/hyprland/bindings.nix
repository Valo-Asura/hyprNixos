{
  pkgs,
  lib,
  ...
}:
let
  mkLuaInline = lib.generators.mkLuaInline;
  toLuaString = builtins.toJSON;
  superKey = "SUPER";
  superShift = "SUPER + SHIFT";
  superAlt = "SUPER + ALT";
  ctrlKey = "CTRL";

  mkBind = keys: dispatcher: opts: {
    _args = [
      keys
      (mkLuaInline dispatcher)
    ]
    ++ lib.optional (opts != null) opts;
  };

  exec = command: "hl.dsp.exec_cmd(${toLuaString command})";
  focusWorkspace = workspace: "hl.dsp.focus({ workspace = ${toLuaString workspace} })";
  moveToWorkspace = workspace: "hl.dsp.window.move({ workspace = ${toLuaString workspace} })";
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      (mkBind "${superKey} + Q" "hl.dsp.window.close()" null)
      (mkBind "${superKey} + H" "hl.dsp.exit()" null)
      (mkBind "${superKey} + F" (exec "${pkgs.thunar}/bin/thunar") null)
      (mkBind "${superKey} + G" "hl.dsp.window.float({ action = \"toggle\" })" null)
      (mkBind "${superKey} + J" "hl.dsp.layout(\"togglesplit\")" null)
      (mkBind "${superKey} + B" (exec "${pkgs.brave}/bin/brave") null)
      (mkBind "${superKey} + T" (exec "${pkgs.kitty}/bin/kitty") null)
      (mkBind "${superKey} + I" (exec "code") null)
      (mkBind "${superKey} + E" (exec "${pkgs.telegram-desktop}/bin/telegram-desktop") null)
      (mkBind "${superKey} + W" (exec "${pkgs.wofi}/bin/wofi") null)
      (mkBind "${ctrlKey} + L" (exec "/run/current-system/sw/bin/vibeshell-safe-lock") null)
      (mkBind "${superKey} + L" (exec "/run/current-system/sw/bin/vibeshell-safe-lock") null)
      (mkBind "${superKey} + C" (exec "vibeshell run dashboard-clipboard") null)
      (mkBind "${superKey} + P" (exec "wallpaper-switch static") null)
      (mkBind "${superShift} + P" (exec "wallpaper-switch animated") null)
      (mkBind "${superAlt} + P" (exec "sync-lock-wallpaper") null)
      (mkBind "Print" (exec "grim -g \"$(slurp)\" - | wl-copy") null)
      (mkBind "${superKey} + Print" (exec "grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png") null)
      (mkBind "${superShift} + Print"
        (exec "grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png")
        null
      )
      (mkBind "${superShift} + E" (exec "${pkgs.wofi-emoji}/bin/wofi-emoji") null)
      (mkBind "${superKey} + F2" (exec "night-shift") null)
    ]
    ++ (builtins.concatLists (
      builtins.genList (
        i:
        let
          ws = i + 1;
        in
        [
          (mkBind "${superKey} + code:1${toString i}" (focusWorkspace (toString ws)) null)
          (mkBind "${superShift} + code:1${toString i}" (moveToWorkspace (toString ws)) null)
        ]
      ) 9
    ))
    ++ [
      (mkBind "${superKey} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
      (mkBind "${superKey} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
      (mkBind "${superKey} + TAB" "hl.dsp.window.resize()" { mouse = true; })
      (mkBind "${superKey} + SUPER_L" (exec "vibeshell run dashboard-widgets") { release = true; })
      (mkBind "XF86AudioMute" (exec "sound-toggle") { locked = true; })
      (mkBind "XF86AudioPlay" (exec "${pkgs.playerctl}/bin/playerctl play-pause") { locked = true; })
      (mkBind "XF86AudioNext" (exec "${pkgs.playerctl}/bin/playerctl next") { locked = true; })
      (mkBind "XF86AudioPrev" (exec "${pkgs.playerctl}/bin/playerctl previous") { locked = true; })
      (mkBind "switch:Lid Switch" (exec "/run/current-system/sw/bin/vibeshell-safe-lock") {
        locked = true;
      })
      (mkBind "XF86AudioRaiseVolume" (exec "sound-up") {
        locked = true;
        repeating = true;
      })
      (mkBind "XF86AudioLowerVolume" (exec "sound-down") {
        locked = true;
        repeating = true;
      })
      (mkBind "XF86MonBrightnessUp" (exec "brightness-up") {
        locked = true;
        repeating = true;
      })
      (mkBind "XF86MonBrightnessDown" (exec "brightness-down") {
        locked = true;
        repeating = true;
      })
    ];
  };
}
