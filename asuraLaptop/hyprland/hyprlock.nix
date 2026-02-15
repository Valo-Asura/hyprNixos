# Hyprlock configuration for screen locking
{ pkgs, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "${./lock-images/lockscreen.png}";
          blur_passes = 0;
          blur_size = 0;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = true;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "";
          shadow_passes = 2;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(232, 236, 255)";
          font_size = 64;
          font_family = "Noto Sans Bold";
          position = "0, 10";
          halign = "center";
          valign = "center";
          shadow_passes = 3;
          shadow_size = 2;
          shadow_color = "rgb(0, 0, 0)";
        }
      ];
    };
  };

  # Add hyprlock to packages
  home.packages = with pkgs; [
    hyprlock
  ];
}
