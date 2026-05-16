# fastfetch — compact Kitty image logo + system info
{ ... }:

let
  logoImage = "/etc/nixos/asuraPc/assets/sans.png";
  cfg = {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "kitty-direct";
      source = logoImage;
      width = 18;
      height = 9;
      position = "left";
      padding = {
        top = 0;
        left = 1;
        right = 2;
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
      {
        type = "host";
        key = "󰌢 ";
        keyColor = "red";
      }
      {
        type = "cpu";
        key = "󰻠 ";
        keyColor = "red";
      }
      {
        type = "gpu";
        key = "󰢮 ";
        keyColor = "red";
      }
      {
        type = "memory";
        key = "󰑭 ";
        keyColor = "red";
      }
      {
        type = "display";
        key = "󰍹 ";
        keyColor = "red";
      }
      "break"
      {
        type = "custom";
        format = "▪ ──── {#31}Software Information{#} ──── ▪";
      }
      {
        type = "os";
        key = " ";
        keyColor = "red";
      }
      {
        type = "kernel";
        key = " ";
        keyColor = "red";
      }
      {
        type = "wm";
        key = " ";
        keyColor = "red";
      }
      {
        type = "shell";
        key = " ";
        keyColor = "red";
      }
      {
        type = "terminal";
        key = " ";
        keyColor = "red";
      }
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
