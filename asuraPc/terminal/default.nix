{
  config,
  lib,
  pkgs,
  ...
}:

let
  logoImage = "${../assets/sans.png}";
  warpIcon = pkgs.writeText "dev.warp.Warp.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="28" fill="${colors.base00}"/>
      <path d="M25 31h78v66H25z" rx="10" fill="${colors.base01}"/>
      <path d="M34 43h64v12H34z" fill="${colors.base0E}"/>
      <path d="M34 65h42v10H34z" fill="${colors.base0D}"/>
      <path d="M34 84h58v8H34z" fill="${colors.base05}"/>
    </svg>
  '';
  footIcon = pkgs.writeText "foot.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="26" fill="${colors.base00}"/>
      <path d="M28 35h60l18 18v55H28z" fill="${colors.base01}"/>
      <path d="M88 35v20h18" fill="${colors.base02}"/>
      <path d="M39 58l18 15-18 15" fill="none" stroke="${colors.base0B}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M64 90h30" stroke="${colors.base0A}" stroke-width="9" stroke-linecap="round"/>
    </svg>
  '';
  ghosttyIcon = pkgs.writeText "com.mitchellh.ghostty.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="28" fill="${colors.base00}"/>
      <path d="M34 94V56c0-20 13-34 30-34s30 14 30 34v38l-9-7-9 7-9-7-9 7-9-7z" fill="${colors.base05}"/>
      <circle cx="53" cy="58" r="6" fill="${colors.base00}"/>
      <circle cx="77" cy="58" r="6" fill="${colors.base00}"/>
      <path d="M53 78h24" stroke="${colors.base00}" stroke-width="7" stroke-linecap="round"/>
    </svg>
  '';
  warpTerminal = pkgs.warp-terminal.overrideAttrs (_oldAttrs: {
    version = "0.2026.05.27.15.44.stable_01";
    src = pkgs.fetchurl {
      url = "https://releases.warp.dev/stable/v0.2026.05.27.15.44.stable_01/warp-terminal-v0.2026.05.27.15.44.stable_01-1-x86_64.pkg.tar.zst";
      hash = "sha256-dvD9s1zVGlvWrc2TmARp5njCHKH0FvocRxg642R2tQc=";
    };
  });
  fastfetchSmart = pkgs.writeShellScriptBin "fastfetch-smart" ''
    logo="${logoImage}"
    cols="$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || printf 120)"

    if [ "$#" -eq 0 ] && { [ "$cols" -lt 56 ] || [ ! -r "$logo" ]; }; then
      exec ${pkgs.fastfetch}/bin/fastfetch \
        --logo none \
        --structure "os:kernel:wm:shell:terminal:memory:colors"
    fi

    if [ -n "''${KITTY_WINDOW_ID:-}" ] || [ "''${TERM:-}" = "xterm-kitty" ]; then
      logo_width=18
      logo_height=9
      logo_padding_right=2
      logo_padding_top=3
      extra_args=()

      if [ "$cols" -lt 88 ]; then
        logo_width=12
        logo_height=6
        logo_padding_right=1
        logo_padding_top=1

        if [ "$#" -eq 0 ]; then
          extra_args+=(--structure "os:kernel:wm:shell:terminal:memory:colors")
        fi
      fi

      exec ${pkgs.fastfetch}/bin/fastfetch \
        --kitty-direct "$logo" \
        --logo-width "$logo_width" \
        --logo-height "$logo_height" \
        --logo-padding-left 1 \
        --logo-padding-right "$logo_padding_right" \
        --logo-padding-top "$logo_padding_top" \
        --logo-recache true \
        "''${extra_args[@]}" \
        "$@"
    fi

    if [ "''${TERM:-}" = "foot" ] || [ "''${TERM_PROGRAM:-}" = "foot" ] || [ -n "''${FOOT_VERSION:-}" ]; then
      logo_width=18
      logo_height=9
      logo_padding_right=2
      logo_padding_top=3
      extra_args=()

      if [ "$cols" -lt 88 ]; then
        logo_width=12
        logo_height=6
        logo_padding_right=1
        logo_padding_top=1

        if [ "$#" -eq 0 ]; then
          extra_args+=(--structure "os:kernel:wm:shell:terminal:memory:colors")
        fi
      fi

      exec ${pkgs.fastfetch}/bin/fastfetch \
        --sixel "$logo" \
        --logo-width "$logo_width" \
        --logo-height "$logo_height" \
        --logo-padding-left 1 \
        --logo-padding-right "$logo_padding_right" \
        --logo-padding-top "$logo_padding_top" \
        --logo-recache true \
        "''${extra_args[@]}" \
        "$@"
    fi

    exec ${pkgs.fastfetch}/bin/fastfetch --chafa "$logo" "$@"
  '';

  colors = {
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
  hex = color: lib.removePrefix "#" color;
in
{
  home.sessionVariables = {
    TERMINAL = "foot";
    VIBESHELL_TERMINAL = "foot";
  };

  xdg.mimeApps = {
    defaultApplications = {
      "application/x-terminal-emulator" = "foot.desktop";
      "x-scheme-handler/terminal" = "foot.desktop";
    };
    associations.added = {
      "application/x-terminal-emulator" = "foot.desktop";
      "x-scheme-handler/terminal" = "foot.desktop";
    };
  };

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
      window_padding_width = "35";
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

      # Appearance — solid opaque background keeps text readable without a wallpaper.
      # Re-enable background_opacity if you add a background_image back.
      background_opacity = "1.0";
      dynamic_background_opacity = "no";
      cursor_blink_interval = 0;
      cursor_shape = "block";
      cursor_beam_thickness = "1.5";

      # Enhanced cursor animations
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.8";
      cursor_trail_start_threshold = 2;

      # Tab bar - enhanced powerline style
      tab_bar_min_tabs = 1;
      tab_bar_style = "custom";
      tab_bar_edge = "bottom";
      tab_bar_align = "left";
      tab_bar_margin_width = "0.0";
      tab_bar_margin_height = "5.0 0.0";
      tab_title_template = config.home.username;

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
      "ctrl+shift+alt+t" = "no_op";

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
    };
  };

  xdg.configFile."kitty/tab_bar.py".text = ''
    from kitty.fast_data_types import Screen, get_boss
    from kitty.tab_bar import DrawData, ExtraData, TabBarData


    def draw_tab(
        draw_data: DrawData,
        screen: Screen,
        tab: TabBarData,
        before: int,
        max_tab_length: int,
        index: int,
        is_last: bool,
        extra_data: ExtraData,
    ) -> int:
        # Render only compact centered tab dots.
        kitty_tab = get_boss().tab_for_id(tab.tab_id)
        manager = kitty_tab.tab_manager_ref() if kitty_tab else None
        tab_count = len(manager.tabs) if manager else 1
        dots_width = max(1, (2 * tab_count) - 1)
        center_start = max(0, (screen.columns - dots_width) // 2)
        if index == 1:
            screen.cursor.x = center_start

        screen.cursor.fg = int(draw_data.active_fg if tab.is_active else draw_data.inactive_fg)
        screen.cursor.bg = int(draw_data.default_bg)
        screen.draw("●" if tab.is_active else "•")

        if not is_last:
            screen.draw(" ")

        return screen.cursor.x
  '';

  xdg.configFile."foot/foot.ini".text = ''
    # Managed by Home Manager: VibeShell Gruvbox terminal profile.
    [main]
    font=JetBrainsMono Nerd Font Mono:size=13
    font-bold=JetBrainsMono Nerd Font Mono:style=Bold:size=13
    font-italic=JetBrainsMono Nerd Font Mono:style=Italic:size=13
    shell=${pkgs.fish}/bin/fish
    term=foot
    pad=18x14
    dpi-aware=yes
    workers=4
    initial-window-size-chars=140x35
    resize-delay-ms=50

    [bell]
    urgent=no
    notify=no
    visual=no

    [scrollback]
    lines=10000
    multiplier=3.0

    [cursor]
    style=block
    blink=no
    beam-thickness=1.5

    [mouse]
    hide-when-typing=yes

    [colors-dark]
    alpha=1.0
    foreground=${hex colors.base05}
    background=${hex colors.base00}
    regular0=${hex colors.base00}
    regular1=${hex colors.base08}
    regular2=${hex colors.base0B}
    regular3=${hex colors.base0A}
    regular4=${hex colors.base0D}
    regular5=${hex colors.base0E}
    regular6=${hex colors.base0C}
    regular7=${hex colors.base05}
    bright0=${hex colors.base03}
    bright1=${hex colors.base08}
    bright2=${hex colors.base0B}
    bright3=${hex colors.base0A}
    bright4=${hex colors.base0D}
    bright5=${hex colors.base0E}
    bright6=${hex colors.base0C}
    bright7=${hex colors.base07}
    selection-foreground=${hex colors.base00}
    selection-background=${hex colors.base0A}
    urls=${hex colors.base0D}

    [csd]
    preferred=none
    border-width=2
    border-color=${hex colors.base0E}

    [tweak]
    font-monospace-warn=no
  '';

  xdg.configFile."ghostty/config".text = ''
    # Managed by Home Manager: VibeShell Gruvbox terminal profile.
    font-family = JetBrainsMono Nerd Font
    font-size = 13
    command = ${pkgs.fish}/bin/fish

    window-decoration = false
    window-padding-x = 18
    window-padding-y = 14
    confirm-close-surface = false
    resize-overlay = never
    mouse-hide-while-typing = true

    background-opacity = 1.0
    cursor-style = block
    cursor-style-blink = false
    unfocused-split-opacity = 0.92
    adjust-cell-height = 4%
    adjust-cursor-thickness = 2

    foreground = ${colors.base05}
    background = ${colors.base00}
    selection-foreground = ${colors.base00}
    selection-background = ${colors.base0A}
    cursor-color = ${colors.base0E}
    palette = 0=${colors.base00}
    palette = 1=${colors.base08}
    palette = 2=${colors.base0B}
    palette = 3=${colors.base0A}
    palette = 4=${colors.base0D}
    palette = 5=${colors.base0E}
    palette = 6=${colors.base0C}
    palette = 7=${colors.base05}
    palette = 8=${colors.base03}
    palette = 9=${colors.base08}
    palette = 10=${colors.base0B}
    palette = 11=${colors.base0A}
    palette = 12=${colors.base0D}
    palette = 13=${colors.base0E}
    palette = 14=${colors.base0C}
    palette = 15=${colors.base07}
  '';

  home.file.".warp/themes/vibeshell-gruvbox.yaml".text = ''
    # Managed by Home Manager. Warp reads custom themes from ~/.warp/themes.
    accent: "${colors.base0E}"
    background: "${colors.base00}"
    foreground: "${colors.base05}"
    details: darker
    terminal_colors:
      normal:
        black: "${colors.base00}"
        red: "${colors.base08}"
        green: "${colors.base0B}"
        yellow: "${colors.base0A}"
        blue: "${colors.base0D}"
        magenta: "${colors.base0E}"
        cyan: "${colors.base0C}"
        white: "${colors.base05}"
      bright:
        black: "${colors.base03}"
        red: "${colors.base08}"
        green: "${colors.base0B}"
        yellow: "${colors.base0A}"
        blue: "${colors.base0D}"
        magenta: "${colors.base0E}"
        cyan: "${colors.base0C}"
        white: "${colors.base07}"
  '';

  home.file.".warp-terminal/user_preferences.json".text = builtins.toJSON {
    theme = "vibeshell-gruvbox";
    font_name = "JetBrainsMono Nerd Font";
    font_size = 13;
    window_opacity = 1.0;
    cursor_shape = "Block";
    enable_bell = false;
  };

  xdg.dataFile."icons/hicolor/scalable/apps/dev.warp.Warp.svg".source = warpIcon;
  xdg.dataFile."icons/hicolor/scalable/apps/foot.svg".source = footIcon;
  xdg.dataFile."icons/hicolor/scalable/apps/com.mitchellh.ghostty.svg".source = ghosttyIcon;

  home.packages = with pkgs; [
    chafa
    fastfetchSmart
    foot
    ghostty
    nerd-fonts.jetbrains-mono
    warpTerminal
  ];

  # Custom shell functions for enhanced terminal experience
  programs.fish.functions = {
    # Custom shell prompt matching the reference screenshot
    fish_prompt = {
      body = ''
        set -l last_status $status

        # Top line: user in dir
        set_color yellow
        echo -n "$USER "
        set_color normal
        echo -n "in "
        set_color red
        echo -n (pwd | string replace -r "^$HOME" "~")
        echo ""

        # Bottom line: ╰─λ
        set_color red
        echo -n " ╰─λ "
        set_color normal
      '';
    };

    # Automatically load fastfetch on startup
    fish_greeting = {
      body = ''
        fastfetch-smart
        echo ""
      '';
    };

    cls = {
      description = "Clear terminal contents and scrollback history";
      body = ''
        clear
        printf '\033[2J\033[3J\033[1;1H'
      '';
    };
  };
}
