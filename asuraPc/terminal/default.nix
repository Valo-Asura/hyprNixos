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
    cowsay # ASCII art cow
    lolcat # Rainbow text
    figlet # ASCII art text
    cmatrix # Matrix-style falling characters
    pipes-rs # Animated pipes screensaver
    sl # Steam locomotive (when you mistype 'ls')
    toilet # Another ASCII art tool
    boxes # Draw boxes around text

    # System monitoring
    htop # Process viewer
    btop # Beautiful system monitor
    fastfetch # System info with style

    # File management
    ranger # Terminal file manager
    mc # Midnight Commander

    # Network tools
    speedtest-cli # Internet speed test
    curl # For weather and fun APIs

    # Development tools
    jq # JSON processor
    yq # YAML processor

    # Fonts
    inter # For Stylix sans-serif font
  ];

  # Custom shell functions for enhanced terminal experience with debug jokes
  programs.fish.functions = {
    # Debug jokes and programming humor
    debug_joke = {
      description = "Random debug and programming jokes";
      body = ''
        set debug_jokes \
          "99 little bugs in the code, 99 little bugs. Take one down, patch it around, 117 little bugs in the code." \
          "Why do programmers prefer dark mode? Because light attracts bugs! 🐛" \
          "A SQL query goes into a bar, walks up to two tables and asks: 'Can I join you?'" \
          "How many programmers does it take to change a light bulb? None. It's a hardware problem." \
          "Why do Java developers wear glasses? Because they can't C#!" \
          "There are only 10 types of people: those who understand binary and those who don't." \
          "Programming is like sex: One mistake and you have to support it for the rest of your life." \
          "A programmer is told to 'go to hell', he finds the worst part of that statement is the 'go to'." \
          "Why did the programmer quit his job? He didn't get arrays! (a raise)" \
          "Debugging: Being the detective in a crime movie where you are also the murderer." \
          "Code never lies, comments sometimes do." \
          "If debugging is the process of removing bugs, then programming must be the process of putting them in." \
          "I would tell you a UDP joke, but you might not get it." \
          "Why do programmers always mix up Halloween and Christmas? Because Oct 31 == Dec 25!" \
          "A byte walks into a bar looking miserable. The bartender asks 'What's wrong?' The byte replies 'Parity error.'" \
          "There are two hard things in computer science: cache invalidation, naming things, and off-by-one errors." \
          "Why did the developer go broke? Because he used up all his cache!" \
          "I'm not a great programmer; I'm just a good programmer with great habits... and Stack Overflow." \
          "The best thing about a Boolean is even if you are wrong, you are only off by a bit." \
          "Why do programmers hate nature? It has too many bugs and no documentation."

        set random_joke $debug_jokes[(random 1 (count $debug_jokes))]
        echo "🐛 DEBUG JOKE:" | figlet -f small | lolcat
        echo "$random_joke" | boxes -d cat | lolcat
        echo ""
      '';
    };

    # System monitor with style
    sysmon = {
      description = "Launch system monitor with style";
      body = ''
        echo "🚀 System Monitor Dashboard" | figlet | lolcat
        echo "Choose your weapon:" | lolcat
        echo "1) Bottom (btm) - Modern system monitor"
        echo "2) Htop - Classic process viewer"
        echo "3) Btop - Beautiful system monitor"
        echo "4) Fastfetch - System info with style"

        read -P "Enter choice (1-4): " choice

        switch $choice
          case 1
            btm
          case 2
            htop
          case 3
            btop
          case 4
            fastfetch
          case '*'
            echo "Invalid choice, launching bottom..." | lolcat
            btm
        end
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

    # Fun terminal greeting with jokes and animations
    greet = {
      description = "Fun terminal greeting with debug jokes and animations";
      body = ''
        # Random greetings
        set greetings \
          "Welcome back, code ninja! 🥷" \
          "Ready to debug the matrix? 🔍" \
          "Time to turn coffee into code! ☕" \
          "Let's make some digital magic! ✨" \
          "Another day, another segfault! 💥" \
          "Compiling... please wait... just kidding! 😄" \
          "Hello World! (but better) 🌍" \
          "Git ready to commit some crimes! 🔥"

        set random_greeting $greetings[(random 1 (count $greetings))]

        # Show greeting with style
        echo $random_greeting | figlet -f small | lolcat

        # Random chance for different startup content
        set rand_num (random 1 100)

        if test $rand_num -le 40
          # 40% chance: Debug joke
          debug_joke
        else if test $rand_num -le 70
          # 30% chance: Fortune + cowsay
          fortune | cowsay | lolcat
          echo ""
        else if test $rand_num -le 85
          # 15% chance: Matrix effect (brief)
          echo "🔴 Entering the Matrix..." | lolcat
          timeout 3 cmatrix -s -C red 2>/dev/null || echo "Matrix loading... 🔴" | lolcat
          clear
          echo "🟢 Welcome to the real world, Neo." | figlet -f small | lolcat
          echo ""
        else
          # 15% chance: Fun message
          echo "🚰 System ready for action!" | lolcat
          echo "🔧 All systems operational!" | figlet -f small | lolcat
          echo ""
        end

        # Always show system status
        echo "📊 Quick System Status:" | lolcat
        echo "💾 Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
        echo "💿 Disk: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')"
        echo "🌡️  CPU Temp: $(sensors 2>/dev/null | grep 'Package id 0' | awk '{print $4}' | sed 's/+//' || echo 'N/A')"
        echo "🕒 Uptime: $(uptime -p)"
        echo ""

        # Random programming tip
        set tips \
          "💡 Tip: Use 'git commit -m \"Fix bug\" --allow-empty' for those 'it works on my machine' moments" \
          "💡 Tip: Remember, there's no place like 127.0.0.1 🏠" \
          "💡 Tip: When in doubt, restart the service. When still in doubt, restart the server." \
          "💡 Tip: The best code is no code. The second best is someone else's code." \
          "💡 Tip: Always code as if the person maintaining your code is a violent psychopath who knows where you live." \
          "💡 Tip: Rubber duck debugging: explain your code to a rubber duck. The duck won't judge you." \
          "💡 Tip: If it's working, don't touch it. If it's not working, blame the network." \
          "💡 Tip: There are only two hard problems in CS: cache invalidation and naming things."

        set random_tip $tips[(random 1 (count $tips))]
        echo $random_tip | lolcat
        echo ""
      '';
    };

    # Project tree with style
    ptree = {
      description = "Show project tree with filtering";
      body = ''
        if test (count $argv) -eq 0
          set depth 3
        else
          set depth $argv[1]
        end

        echo "📁 Project Structure (depth: $depth)" | figlet -f small | lolcat
        tree -C -L $depth -I 'node_modules|.git|target|build|dist|.next|__pycache__'
      '';
    };

    # Fun commands
    weather_fun = {
      description = "Get weather with extra style and animations";
      body = ''
        echo "🌤️  Weather Report" | figlet -f small | lolcat
        curl -s "wttr.in/?format=3" | lolcat
        echo ""
      '';
    };

    joke = {
      description = "Get a random programming joke";
      body = ''
        debug_joke
      '';
    };

    matrix = {
      description = "Enter the Matrix";
      body = ''
        echo "🔴 Entering the Matrix... Press Ctrl+C to exit" | lolcat
        cmatrix -s -C green
      '';
    };
  };
}
