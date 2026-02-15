# Shell configuration
{ pkgs, ... }:

{
  imports = [
    ./quotes.nix
  ];
<<<<<<< HEAD

  home.packages = with pkgs; [
    home-manager
    eza        # Better ls replacement
    bat        # Better cat replacement
    fd         # Better find replacement
    direnv     # Environment management
    fastfetch  # System info tool (used by `ff` alias)
    atuin      # Shell history management
    zoxide     # Smart cd replacement
    fzf        # Fuzzy finder
    starship   # Prompt (managed separately)
    bottom     # System monitor (used by `btm` alias and monitor function)
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];

  # ── Shell tools ──────────────────────────────────────────────────────────────

=======
  home.packages = with pkgs; [
    home-manager
    eza # Better ls replacement
    bat # Better cat replacement
    fd # Better find replacement
    direnv # Environment management
    fastfetch # System info tool
    atuin # Shell history management
    zoxide # Smart cd replacement
    fzf # Fuzzy finder
    starship # Prompt (managed separately)
  ];

  # Enable additional shell tools
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "fuzzy";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

<<<<<<< HEAD
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  # ── Fish shell ────────────────────────────────────────────────────────────────

=======
  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Fish integration is handled automatically
  };

  # Fish shell configuration
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  programs.fish = {
    enable = true;

    shellInit = ''
<<<<<<< HEAD
      # Suppress default greeting
=======
      # Set fish greeting
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      set -U fish_greeting

      # Direnv hook
      direnv hook fish | source

<<<<<<< HEAD
      # Optional shell banner. Leave it off by default so terminals open fast.
      if test "$ASURA_SHOW_SHELL_BANNER" = "1"
        and not set -q __MICROFETCH_RAN
        and not set -q __microfetch_in_subshell
        and status is-interactive
        set -gx __MICROFETCH_RAN 1
        microfetch
        echo
=======
      # Display system info and quote on new sessions
      if not set -q __MICROFETCH_RAN
        and not set -q __microfetch_in_subshell
        and status is-interactive
        set -gx __MICROFETCH_RAN 1

        # Show system info first
        microfetch
        echo

        # Then show a random quote
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        random-quote
        echo
      end
    '';

    interactiveShellInit = ''
<<<<<<< HEAD
      # Tab: accept autosuggestion if available, else complete
=======
      # Enhanced tab completion
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      function __tab_or_accept --description 'Accept autosuggestion or complete'
        set -l sug (commandline -P)
        if test -n "$sug"
          accept-autosuggestion
        else
          commandline -f complete
        end
      end
      bind \t __tab_or_accept

<<<<<<< HEAD
      # Vi-mode convenience bindings
      bind -M insert \cf accept-autosuggestion
      bind -M insert \ce end-of-line
=======
      # Vi mode bindings
      bind -M insert \cf accept-autosuggestion
      bind -M insert \ce end-of-line

      # Better history search
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      bind -M insert \cr history-pager
      bind -M insert \cs pager-toggle-search
    '';

    shellAliases = {
<<<<<<< HEAD
      # ── ls / directory ─────────────────────────────────────────────────────
      ls   = "eza --icons --group-directories-first --classify=always";
      ll   = "eza -lh --icons --group-directories-first --git --time-style=relative";
      la   = "eza -lah --icons --group-directories-first --git --time-style=relative";
      tree = "eza --tree --icons --level=3";

      # ── Better core utils ──────────────────────────────────────────────────
      cat  = "bat --style=auto";
      grep = "rg";
      find = "fd";
      cd   = "z";

      # ── Git ────────────────────────────────────────────────────────────────
      g    = "git";
      gs   = "git status";
      ga   = "git add";
      gc   = "git commit";
      gp   = "git push";
      gl   = "git log --oneline --graph";

      # ── System monitoring ──────────────────────────────────────────────────
      btm  = "bottom";        # TUI system monitor
      htop = "btop";          # btop is installed system-wide
      temp = "sensors | grep -E '(Core|Package)' | head -4";

      # ── NixOS ──────────────────────────────────────────────────────────────
      rebuild = "sudo nixos-rebuild switch --flake .";
      update  = "nix flake update";
      clean   = "sudo nix-collect-garbage -d";
      clean-store = "nix-storage-clean";

      # ── Terminal / misc ────────────────────────────────────────────────────
      ff      = "fastfetch";
      quote   = "random-quote";
      qotd    = "quote-of-the-day";
      weather = "curl -s 'wttr.in/?format=3'";
      ports   = "ss -tuln";
      ping    = "ping -c 5";
      code    = "kiro";
      cursor  = "cursor";
      zed     = "zeditor";
      c       = "clear";
      e       = "exit";

      # ── Safety ─────────────────────────────────────────────────────────────
=======
      # Enhanced ls commands
      ls = "eza --icons --group-directories-first --classify=always";
      ll = "eza -lh --icons --group-directories-first --git --time-style=relative";
      la = "eza -lah --icons --group-directories-first --git --time-style=relative";
      tree = "eza --tree --icons --level=3";

      # Better cat and grep
      cat = "bat --style=auto";
      grep = "rg";
      find = "fd";
      cd = "z"; # Use zoxide for smart cd

      # Git shortcuts
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";

      # System shortcuts
      rebuild = "sudo nixos-rebuild switch --flake .";
      update = "nix flake update";
      clean = "sudo nix-collect-garbage -d";
      ff = "fastfetch"; # Quick fastfetch alias
      quote = "random-quote"; # Random quote
      qotd = "quote-of-the-day"; # Quote of the day

      # Fun terminal tools
      weather = "curl -s 'wttr.in/?format=3' | lolcat";
      moon = "curl -s 'wttr.in/Moon' | head -23";
      matrix = "cmatrix -s -C blue";
      pipes = "pipes.sh";

      # System monitoring
      top = "bottom";
      htop = "btop";
      sys = "neofetch";
      temp = "sensors | grep -E '(Core|Package)' | head -4";

      # File operations
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

<<<<<<< HEAD
      # ── Dev ────────────────────────────────────────────────────────────────
      y = "yazi";   # fast TUI file manager
    };

    functions = {
      start-hyprland = {
        description = "Start Hyprland from a TTY, with a guard against relaunching inside Wayland";
        body = ''
          if test "$FORCE_START_HYPRLAND" = "1"
            command start-hyprland $argv
            return $status
          end

          if set -q HYPRLAND_INSTANCE_SIGNATURE; or test "$XDG_SESSION_TYPE" = "wayland"; or set -q WAYLAND_DISPLAY
            set -l current_display "unknown"
            if set -q WAYLAND_DISPLAY
              set current_display $WAYLAND_DISPLAY
            end

            echo "Hyprland is already running in this shell on $current_display."
            echo "Switch to a text TTY or log out before starting a new compositor session."
            echo "If you really need to bypass this guard, run: FORCE_START_HYPRLAND=1 start-hyprland"
            return 1
          end

          command start-hyprland $argv
        '';
      };

      # Directory tree using eza (not system tree)
      ltree = {
        description = "Show directory tree (depth 3, no .git/node_modules)";
        body = ''
          set target (test (count $argv) -ge 1; and echo $argv[1]; or echo ".")
          eza --tree --icons --level=3 \
              --ignore-glob=".git|node_modules|.next|dist|build" \
              $target
        '';
      };

      # System monitor wrapper
      monitor = {
        description = "Open bottom system monitor";
        body = ''
=======
      # Network
      ping = "ping -c 5";
      ports = "ss -tuln";

      # Development
      code = "kiro";
      c = "clear";
      e = "exit";

      # Fun stuff
      starwars = "telnet towel.blinkenlights.nl";
      parrot = "curl parrot.live";
      nyan = "telnet nyancat.dakko.us";
    };

    functions = {
      # Fun and useful functions
      weather = {
        description = "Get weather for a city (usage: weather [city])";
        body = ''
          set city $argv[1]
          if test -z "$city"
            set city "auto:ip"
          end
          curl -s "wttr.in/$city?format=3" | lolcat
        '';
      };

      # Directory tree with style
      ltree = {
        description = "Show directory tree with better formatting";
        body = ''
          if test (count $argv) -eq 0
            tree -C -a -I '.git|node_modules|.next|dist|build' --dirsfirst
          else
            tree -C -a -I '.git|node_modules|.next|dist|build' --dirsfirst $argv[1]
          end
        '';
      };

      # System monitoring with style
      monitor = {
        description = "Show system monitoring with bottom";
        body = ''
          echo "🖥️  System Monitor (Press 'q' to quit)"
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
          bottom
        '';
      };

<<<<<<< HEAD
      # Make a dir and cd into it
=======
      # Interactive file manager
      files = {
        description = "Open ranger file manager";
        body = ''
          ranger
        '';
      };

      # Speed test with style
      speedtest = {
        description = "Run internet speed test";
        body = ''
          echo "🚀 Running speed test..."
          speedtest-cli --simple | lolcat
        '';
      };

      # Fun cowsay with fortune
      wisdom = {
        description = "Get wisdom from a cow";
        body = ''
          if command -v fortune >/dev/null 2>&1; and command -v cowsay >/dev/null 2>&1
            fortune | cowsay | lolcat
          else
            echo "🐄 Moo! Install fortune and cowsay for wisdom!"
          end
        '';
      };

      # ASCII art banner
      banner = {
        description = "Create ASCII art banner (usage: banner 'text')";
        body = ''
          if test (count $argv) -eq 0
            figlet "NixOS Rocks!" | lolcat
          else
            figlet "$argv[1]" | lolcat
          end
        '';
      };

      # Interactive dialog menu
      menu = {
        description = "Show interactive system menu";
        body = ''
          set choice (dialog --clear --backtitle "Asura's Terminal Menu" \
            --title "System Tools" \
            --menu "Choose an option:" 15 50 8 \
            1 "System Info (neofetch)" \
            2 "System Monitor (bottom)" \
            3 "File Manager (ranger)" \
            4 "Speed Test" \
            5 "Weather" \
            6 "Random Quote" \
            7 "Directory Tree" \
            8 "Exit" \
            3>&1 1>&2 2>&3)

          clear

          switch $choice
            case 1
              neofetch
            case 2
              bottom
            case 3
              ranger
            case 4
              speedtest
            case 5
              weather
            case 6
              random-quote
            case 7
              ltree
            case 8
              echo "👋 Goodbye!"
            case "*"
              echo "❌ Cancelled or invalid choice"
          end
        '';
      };

      # Enhanced directory navigation
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      mkcd = {
        description = "Create directory and cd into it";
        body = ''
          mkdir -p $argv[1]
          cd $argv[1]
        '';
      };

<<<<<<< HEAD
      # Detailed system snapshot
      sysinfo = {
        description = "Show system snapshot: info / memory / disk / temps";
=======
      # Project initialization with direnv
      init-project = {
        description = "Initialize a new project with direnv";
        body = ''
          if test (count $argv) -eq 0
            echo "Usage: init-project <project-name> [language]"
            return 1
          end

          set project_name $argv[1]
          set language $argv[2]

          mkdir -p $project_name
          cd $project_name

          # Create .envrc for direnv
          if test "$language" = "node" -o "$language" = "js"
            echo "use node" > .envrc
            echo "node_modules/" > .gitignore
            echo '{"name": "'$project_name'", "version": "1.0.0"}' > package.json
          else if test "$language" = "python" -o "$language" = "py"
            echo "use flake" > .envrc
            echo "__pycache__/" > .gitignore
            echo ".venv/" >> .gitignore
          else if test "$language" = "rust"
            echo "use flake" > .envrc
            echo "target/" > .gitignore
            echo "Cargo.lock" >> .gitignore
          else
            echo "use flake" > .envrc
          end

          # Initialize git
          git init
          echo "# $project_name" > README.md

          # Allow direnv
          direnv allow

          echo "Project $project_name initialized with $language setup"
        '';
      };

      # System information
      sysinfo = {
        description = "Show detailed system information";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        body = ''
          echo "🖥️  System Information"
          echo "===================="
          microfetch
          echo ""
<<<<<<< HEAD
          echo "💾 Memory:"
          free -h
          echo ""
          echo "💿 Disk:"
          df -h / /home 2>/dev/null | tail -n +2
          echo ""
          echo "🌡️  Temps:"
=======
          echo "💾 Memory Usage:"
          free -h
          echo ""
          echo "💿 Disk Usage:"
          df -h / /home 2>/dev/null | tail -n +2
          echo ""
          echo "🌡️  Temperature:"
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
          sensors | grep -E "(Core|Package)" | head -4
        '';
      };

<<<<<<< HEAD
      # Quick project scaffold with direnv
      init-project = {
        description = "Scaffold a new project with direnv (usage: init-project <name> [node|py|rust])";
        body = ''
          if test (count $argv) -eq 0
            echo "Usage: init-project <project-name> [node|py|rust]"
            return 1
          end

          set project_name $argv[1]
          set language (test (count $argv) -ge 2; and echo $argv[2]; or echo "")

          mkdir -p $project_name
          cd $project_name
          git init
          echo "# $project_name" > README.md

          switch $language
            case "node" "js"
              echo "use node" > .envrc
              echo "node_modules/" > .gitignore
              echo "{\"name\": \"$project_name\", \"version\": \"1.0.0\"}" > package.json
            case "python" "py"
              echo "use flake" > .envrc
              printf "__pycache__/\n.venv/\n" > .gitignore
            case "rust"
              echo "use flake" > .envrc
              printf "target/\n" > .gitignore
            case "*"
              echo "use flake" > .envrc
          end

          direnv allow
          echo "✅ Project '$project_name' initialised"
        '';
      };

      # Motivational snippets
      motivate = {
        description = "Contextual programming quotes (usage: motivate [debug|frustrated|tired|confident])";
        body = ''
          switch $argv[1]
            case "debug" "debugging" "bug"
              echo "🐛 \"Debugging is twice as hard as writing the code.\" — Brian Kernighan"
            case "frustrated" "angry" "mad"
              echo "😤 \"The most important property of a program is whether it accomplishes the intention of its user.\" — C.A.R. Hoare"
            case "tired" "sleepy" "exhausted"
              echo "😴 \"The best error message is the one that never shows up.\" — Thomas Fuchs"
            case "confident" "happy" "good"
              echo "😎 \"Talk is cheap. Show me the code.\" — Linus Torvalds"
            case "*"
              echo "💭 Usage: motivate [debug|frustrated|tired|confident]"
=======
      # Motivational quotes for different moods
      motivate = {
        description = "Get a motivational quote when you need it";
        body = ''
          set mood $argv[1]

          switch $mood
            case "debug" "debugging" "bug"
              echo "🐛 Debugging Wisdom:"
              echo "\"Debugging is twice as hard as writing the code in the first place.\" - Brian Kernighan"
              echo "\"If debugging is the process of removing software bugs, then programming must be the process of putting them in.\" - Edsger Dijkstra"
            case "frustrated" "angry" "mad"
              echo "😤 Take a Deep Breath:"
              echo "\"The most important property of a program is whether it accomplishes the intention of its user.\" - C.A.R. Hoare"
              echo "\"Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live.\" - John Woods"
            case "tired" "sleepy" "exhausted"
              echo "😴 Time for a Break:"
              echo "\"The best error message is the one that never shows up.\" - Thomas Fuchs"
              echo "\"Sometimes it pays to stay in bed on Monday, rather than spending the rest of the week debugging Monday's code.\" - Dan Salomon"
            case "confident" "happy" "good"
              echo "😎 Keep It Up:"
              echo "\"Talk is cheap. Show me the code.\" - Linus Torvalds"
              echo "\"Any fool can write code that a computer can understand. Good programmers write code that humans can understand.\" - Martin Fowler"
            case "*"
              echo "💭 Usage: motivate [debug|frustrated|tired|confident]"
              echo "Or just use 'quote' for a random quote!"
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
          end
        '';
      };
    };
  };

<<<<<<< HEAD
  # ── Starship prompt ───────────────────────────────────────────────────────────

=======
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
<<<<<<< HEAD
      command_timeout = 1000;   # ms — raised slightly to avoid false timeouts
=======
      command_timeout = 800;
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)

      format = "$username$hostname$directory$git_branch$git_status$direnv$cmd_duration$line_break$character";

      username = {
        show_always = true;
<<<<<<< HEAD
        style_user  = "bold fg:81";
        format      = "[$user]($style)";
=======
        style_user = "bold fg:81";
        format = "[$user]($style)";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      };

      hostname = {
        ssh_only = false;
<<<<<<< HEAD
        style    = "bold fg:45";
        format   = "[@$hostname]($style) ";
      };

      directory = {
        truncation_length  = 3;
        truncation_symbol  = "…/";
        style              = "bold fg:33";
        format             = "[$path]($style) ";
=======
        style = "bold fg:45";
        format = "[@$hostname]($style) ";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold fg:33";
        format = "[$path]($style) ";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      };

      git_branch = {
        symbol = " ";
<<<<<<< HEAD
        style  = "bold fg:135";
=======
        style = "bold fg:135";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
<<<<<<< HEAD
        style  = "fg:135";
        format = "[$all_status$ahead_behind]($style) ";
      };

      direnv = {
        format   = "[$symbol$loaded/$allowed]($style) ";
        symbol   = "📁 ";
        style    = "bold fg:208";
=======
        style = "fg:135";
        format = "[$all_status$ahead_behind]($style) ";
      };

      # Direnv indicator
      direnv = {
        format = "[$symbol$loaded/$allowed]($style) ";
        symbol = "📁 ";
        style = "bold fg:208";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        disabled = false;
      };

      cmd_duration = {
        min_time = 500;
<<<<<<< HEAD
        style    = "fg:250";
        format   = "[$duration]($style) ";
=======
        style = "fg:250";
        format = "[$duration]($style) ";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      };

      character = {
        success_symbol = "[❯](bold fg:82)";
<<<<<<< HEAD
        error_symbol   = "[❯](bold fg:196)";
        vicmd_symbol   = "[❮](bold fg:214)";
=======
        error_symbol = "[❯](bold fg:196)";
        vicmd_symbol = "[❮](bold fg:214)";
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
      };
    };
  };
}
