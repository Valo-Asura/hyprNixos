# fastfetch — Kitty image logo on the right + system info (see fastfetch Logo options wiki)
{ ... }:

let
  logoImage = ../../../asuraPc/assets/ax.png;
  cfg = {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "kitty";
      source = toString logoImage;
      width = 30;
      height = 15;
      position = "left";
      padding = {
        top = 1;
        left = 2;
        right = 3;
      };
    };
    display = {
      separator = " :: ";
      brightColor = true;
    };
    modules = [
      "break"
      {
        type = "custom";
        format = "▪ ──── {#31}Hardware Information{#} ──── ▪";
      }
      { type = "host"; key = "󰌢 "; keyColor = "red"; }
      { type = "cpu"; key = "󰻠 "; keyColor = "red"; }
      { type = "gpu"; key = "󰢮 "; keyColor = "red"; }
      { type = "memory"; key = "󰑭 "; keyColor = "red"; }
      { type = "display"; key = "󰍹 "; keyColor = "red"; }
      "break"
      {
        type = "custom";
        format = "▪ ──── {#31}Software Information{#} ──── ▪";
      }
      { type = "os"; key = " "; keyColor = "red"; }
      { type = "kernel"; key = " "; keyColor = "red"; }
      { type = "wm"; key = " "; keyColor = "red"; }
      { type = "shell"; key = " "; keyColor = "red"; }
      { type = "terminal"; key = " "; keyColor = "red"; }
      "break"
      {
        type = "colors";
        symbol = "circle";
      }
    ];
  };
in
{
  xdg.configFile."fastfetch/config.jsonc" = {
    force = true;
    text = builtins.toJSON cfg;
  };
}
