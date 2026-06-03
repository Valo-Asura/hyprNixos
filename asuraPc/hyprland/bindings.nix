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
  noctalia = "/run/current-system/sw/bin/noctalia";
  noctaliaSafeLock = "/run/current-system/sw/bin/noctalia-safe-lock";
  skwd = "/run/current-system/sw/bin/skwd";

  screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
    set -euo pipefail

    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"

    file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.grim}/bin/grim "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
  '';

  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
    set -euo pipefail

    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"

    geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
    file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.grim}/bin/grim -g "$geometry" "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
  '';

  screenshotEdit = pkgs.writeShellScriptBin "screenshot-edit" ''
    set -euo pipefail

    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"

    geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
    file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.grim}/bin/grim -g "$geometry" "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
    ${pkgs.swappy}/bin/swappy -f "$file"
  '';

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
      (mkBind "${superKey} + H" (exec "hyprshutdown") null)
      (mkBind "${superKey} + F" (exec "${pkgs.thunar}/bin/thunar") null)
      (mkBind "${superKey} + G" "hl.dsp.window.float({ action = \"toggle\" })" null)
      (mkBind "${superKey} + J" "hl.dsp.layout(\"togglesplit\")" null)
      (mkBind "${superKey} + B" (exec "${pkgs.brave}/bin/brave") null)
      (mkBind "${superKey} + T" (exec "${pkgs.kitty}/bin/kitty") null)
      (mkBind "${superKey} + I" (exec "code") null)
      (mkBind "${superKey} + E" (exec "${pkgs.telegram-desktop}/bin/telegram-desktop") null)
      (mkBind "${superKey} + A" (exec "${noctalia} msg panel-toggle launcher") null)
      (mkBind "${superKey} + D" (exec "${noctalia} msg panel-toggle control-center") null)
      (mkBind "${ctrlKey} + L" (exec noctaliaSafeLock) null)
      (mkBind "${superKey} + L" (exec noctaliaSafeLock) null)
      (mkBind "${superKey} + V" (exec "${noctalia} msg panel-toggle clipboard") null)
      (mkBind "${superKey} + P" (exec "${skwd} wall toggle") null)
      (mkBind "${superShift} + P" (exec "${skwd} wall cache_rebuild") null)
      (mkBind "${superAlt} + P" (exec "${skwd} wall restore") null)
      (mkBind "Print" (exec "${screenshotEdit}/bin/screenshot-edit") null)
      (mkBind "${superKey} + Print" (exec "${screenshotFull}/bin/screenshot-full") null)
      (mkBind "${superShift} + Print" (exec "${screenshotRegion}/bin/screenshot-region") null)
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
      (mkBind "${superKey} + SUPER_L" (exec "${noctalia} msg panel-toggle launcher") {
        release = true;
      })
      (mkBind "XF86AudioMute" (exec "sound-toggle") { locked = true; })
      (mkBind "XF86AudioPlay" (exec "${pkgs.playerctl}/bin/playerctl play-pause") { locked = true; })
      (mkBind "XF86AudioNext" (exec "${pkgs.playerctl}/bin/playerctl next") { locked = true; })
      (mkBind "XF86AudioPrev" (exec "${pkgs.playerctl}/bin/playerctl previous") { locked = true; })
      (mkBind "switch:Lid Switch" (exec noctaliaSafeLock) {
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
