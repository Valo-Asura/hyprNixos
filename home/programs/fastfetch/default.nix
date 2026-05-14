# fastfetch — Kitty image logo on the right + system info (see fastfetch Logo options wiki)
{ ... }:

let
  logoImage = ../../../asuraPc/assets/ax.png;
  cfg = {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "kitty";
      source = toString logoImage;
      width = 36;
      height = 18;
      position = "right";
      padding = {
        top = 0;
        left = 2;
        right = 1;
      };
    };
    display = {
      separator = ": ";
      brightColor = true;
      color = {
        keys = "cyan";
        title = "bright_blue";
      };
    };
    modules = [
      "title"
      "separator"
      "os"
      "host"
      "kernel"
      "wm"
      "shell"
      "terminal"
      "terminalfont"
      "cpu"
      "gpu"
      "memory"
      "swap"
      "disk"
      "colors"
    ];
  };
in
{
  xdg.configFile."fastfetch/config.jsonc" = {
    force = true;
    text = builtins.toJSON cfg;
  };
}
