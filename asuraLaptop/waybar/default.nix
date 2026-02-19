# Waybar — declarative config (files sourced from ./config and ./style.css)
{ config, pkgs, ... }:

{
  programs.waybar.enable = true;

  home.packages = with pkgs; [
    papirus-icon-theme   # tray icons + consistent icon theme
  ];

  xdg.configFile."waybar/config".source = ./config;
  xdg.configFile."waybar/style.css".source = ./style.css;
}
