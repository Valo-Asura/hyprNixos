# Wofi is a launcher for Wayland, inspired by rofi.
{ config, pkgs, lib, ... }:
let
  accent = "A594FD";
  background = "0a0a0a";
  background-alt = "1a1a1a";
  foreground = "fcfcfc";
  font = "SFProDisplay Nerd Font";
  rounding = 10;
  font-size = 13;
in {

  home.packages = with pkgs; [ wofi-emoji ];

  programs.wofi = {
    enable = true;
    settings = {
      allow_markup = true;
      width = 600;
      show = "drun";
      prompt = "Apps";
      normal_window = true;
      layer = "top";
      term = "foot";
      height = "205px";
      orientation = "vertical";
      halign = "fill";
      line_wrap = "on";
      dynamic_lines = false;
      allow_images = true;
      image_size = 24;
      exec_search = false;
      hide_search = false;
      parse_search = false;
      insensitive = true;
      hide_scroll = true;
      no_actions = true;
      sort_order = "default";
      gtk_dark = true;
      filter_rate = 100;
      key_expand = "Tab";
      key_exit = "Escape";
    };

    style = lib.mkForce
      # css
      ''
        * {
          font-family: "${font}";
          font-weight: 500;
          font-size: ${toString font-size}px;
        }

        #window {
          background-color: ${background};
          color: ${foreground};
          border-radius: ${toString rounding}px;
        }

        #outer-box {
          padding: 20px;
        }

        #input {
          background-color: ${background-alt};
          border: 0px solid ${accent};
          color: ${foreground};
          
        }

        #scroll {
          margin-top: 10px;
        }

        #inner-box {
          width : 600px;
        }

        #img {
          padding-right: 8px;
        }

        #text {
          color: ${foreground};
        }

        #text:selected {
          color: ${foreground};
        }

        #entry {
          padding: 6px;
        }

        #entry:selected {
          background-color: ${accent};
          color: ${foreground};
        }

        #unselected {}

        #selected {}

        #input,
        #entry:selected {
          border-radius: ${toString rounding}px;
        }
      '';
  };
}