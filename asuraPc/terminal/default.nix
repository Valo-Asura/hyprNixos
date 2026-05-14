{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Local assets (committed under asuraPc/assets) — used as Kitty background.
  kittyWallpaper = ../assets/sans.png;
  kittyWallpaperAlt = ../assets/ax.png;

  colors = config.lib.stylix.colors.withHashtag or {
    base00 = "#282828";
    base01 = "#32302f";
    base02 = "#3c3836";
    base03 = "#504945";
    base04 = "#665c54";
    base05 = "#d4be98";
    base06 = "#d5c4a1";
    base07 = "#ebdbb2";
    base08 = "#ea6962";
    base09 = "#e78a4e";
    base0A = "#d8a657";
    base0B = "#a9b665";
    base0C = "#89b482";
    base0D = "#7daea3";
    base0E = "#d3869b";
    base0F = "#bd6f3e";
  };
in
{
  programs.kitty = {
    enable = true;

    # Let Stylix handle font and colors
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };

    settings = {
      # Window settings — padding + border tuned for wallpaper + Hyprland blur
      confirm_os_window_close = 0;
      hide_window_decorations = "yes";
      window_padding_width = "20";
      window_margin_width = "0";

      # Enhanced visual settings (magenta accent like reference rices)
      draw_minimal_borders = "yes";
      window_border_width = "2pt";
      active_border_color = colors.base0E;
      inactive_border_color = colors.base02;

      # Solid background color from Stylix will be used
      # (Background image removed for readability)

      # Terminal size - bigger for better productivity
      remember_window_size = "no";
      initial_window_width = "140c";
      initial_window_height = "35c";

      # Audio
      enable_audio_bell = "no";
      visual_bell_duration = "0.0";

      # Appearance — transparency works with Hyprland blur; wallpaper shows through
      background_opacity = "0.84";
      dynamic_background_opacity = "yes";
      cursor_blink_interval = 0;
      cursor_shape = "block";
      cursor_beam_thickness = "1.5";

      # Enhanced cursor animations
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.8";
      cursor_trail_start_threshold = 2;

      # Tab bar - enhanced powerline style
      tab_bar_min_tabs = 1;
      tab_bar_style = "powerline";
      tab_bar_edge = "bottom";
      tab_powerline_style = "round";
      tab_bar_margin_width = "0.0";
      tab_bar_margin_height = "5.0 0.0";
      tab_title_template = " {fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title} ";

      # Scrollback and history
      scrollback_lines = 10000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";

      # Performance optimizations
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";

      # Shell with custom greeting
      shell = "${pkgs.fish}/bin/fish";

      # URL handling
      url_color = colors.base0D;
      url_style = "curly";
      open_url_with = "default";

      # Selection
      selection_foreground = colors.base00;
      selection_background = colors.base0A;

      # Tabs follow the active Stylix palette instead of a hardcoded theme.
      tab_bar_background = colors.base00;
      active_tab_background = colors.base0A;
      active_tab_foreground = colors.base00;
      inactive_tab_background = colors.base01;
      inactive_tab_foreground = colors.base05;
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";

      # Base16 Terminal Colors from Stylix
      foreground = colors.base05;
      background = colors.base00;
      color0 = colors.base00;
      color1 = colors.base08;
      color2 = colors.base0B;
      color3 = colors.base0A;
      color4 = colors.base0D;
      color5 = colors.base0E;
      color6 = colors.base0C;
      color7 = colors.base05;
      color8 = colors.base03;
      color9 = colors.base08;
      color10 = colors.base0B;
      color11 = colors.base0A;
      color12 = colors.base0D;
      color13 = colors.base0E;
      color14 = colors.base0C;
      color15 = colors.base07;

      # Advanced features
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";

      # Notifications for long-running commands
      notify_on_cmd_finish = "unfocused 30.0";
    };

    keybindings = {
      # Theme and appearance
      "ctrl+shift+u" = "kitten themes";
      "ctrl+shift+f2" = "edit_config_file";

      # Tab management
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+q" = "close_tab";

      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";

      # Scrollback
      "ctrl+shift+h" = "show_scrollback";
      "ctrl+shift+g" = "show_last_command_output";

      # Font size
      "ctrl+shift+equal" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # Useful shortcuts
      "ctrl+shift+f" =
        "launch --type=overlay --stdin-source=@screen_scrollback fzf --no-sort --no-mouse --exact -i";

      # Fun shortcuts
      "ctrl+shift+j" = "launch --type=tab fish -c joke";
      "ctrl+shift+m" = "launch --type=tab fish -c matrix";
      "ctrl+alt+w" = "launch --type=tab fish -c weather_fun";
    };
  };

  home.packages = with pkgs; [
    # Enhanced terminal tools
    eza # Better ls with icons and colors
    bat # Better cat with syntax highlighting
    bottom # Better htop/top with graphs
    tree # Directory tree visualization
    fzf # Fuzzy finder
    dialog # Terminal UI dialogs

    # Fun terminal tools
    fortune # Random quotes and jokes
    pipes-rs # Animated pipes screensaver
    sl # Steam locomotive (when you mistype 'ls')

    # System monitoring
    htop # Process viewer
    btop # Beautiful system monitor
    fastfetch # System info with style

    # File management
    ranger # Terminal file manager
    mc # Midnight Commander

    # Network tools
    curl # For weather and fun APIs

    # Development tools
    jq # JSON processor
    yq # YAML processor

    # Fonts
    inter # For Stylix sans-serif font
  ];

  # Custom shell functions for enhanced terminal experience
  programs.fish.functions = {
    # Clear terminal completely
    cls = {
      description = "Clear terminal screen and scrollback history";
      body = ''
        clear
        printf '\033[2J\033[3J\033[1;1H'
      '';
    };

    # Interactive file explorer
    explore = {
      description = "Interactive file explorer with dialog";
      body = ''
        set choice (dialog --menu "File Explorer" 15 50 4 \
          "1" "Ranger (Classic)" \
          "2" "MC (Midnight Commander)" \
          "3" "Tree View" \
          "4" "Eza List" \
          3>&1 1>&2 2>&3)

        switch $choice
          case 1
            ranger
          case 2
            mc
          case 3
            tree -C -L 3
          case 4
            eza -la --tree --level=2 --icons
        end
      '';
    };
  };
}
