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
          blur_passes = 1;
          blur_size = 3;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "Password...";
          shadow_passes = 2;
        }
      ];

      label = [
        {
          monitor = "";
          text = "Hi there, $USER";
          color = "rgb(200, 200, 200)";
          font_size = 25;
          font_family = "Noto Sans";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(200, 200, 200)";
          font_size = 55;
          font_family = "Noto Sans";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # Add hyprlock to packages
  home.packages = with pkgs; [
    hyprlock
  ];
}
