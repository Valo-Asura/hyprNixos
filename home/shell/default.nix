# Shell configuration
{ pkgs, ... }:

{
  imports = [
    ./quotes.nix
  ];
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

  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Fish integration is handled automatically
  };

  # Fish shell configuration
  programs.fish = {
    enable = true;

    shellInit = ''
      # Set fish greeting
      set -U fish_greeting

      # Direnv hook
      direnv hook fish | source

      # Display system info and quote on new sessions
      if not set -q __MICROFETCH_RAN
        and not set -q __microfetch_in_subshell
        and status is-interactive
        set -gx __MICROFETCH_RAN 1

        # Show system info first
        microfetch
        echo

        # Then show a random quote
        random-quote
        echo
      end
    '';

    interactiveShellInit = ''
      # Enhanced tab completion
      function __tab_or_accept --description 'Accept autosuggestion or complete'
        set -l sug (commandline -P)
        if test -n "$sug"
          accept-autosuggestion
        else
          commandline -f complete
        end
      end
      bind \t __tab_or_accept

      # Vi mode bindings
      bind -M insert \cf accept-autosuggestion
      bind -M insert \ce end-of-line

      # Better history search
      bind -M insert \cr history-pager
      bind -M insert \cs pager-toggle-search
    '';

    shellAliases = {
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
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

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
          bottom
        '';
      };

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
      mkcd = {
        description = "Create directory and cd into it";
        body = ''
          mkdir -p $argv[1]
          cd $argv[1]
        '';
      };

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
        body = ''
          echo "🖥️  System Information"
          echo "===================="
          microfetch
          echo ""
          echo "💾 Memory Usage:"
          free -h
          echo ""
          echo "💿 Disk Usage:"
          df -h / /home 2>/dev/null | tail -n +2
          echo ""
          echo "🌡️  Temperature:"
          sensors | grep -E "(Core|Package)" | head -4
        '';
      };

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
          end
        '';
      };
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 800;

      format = "$username$hostname$directory$git_branch$git_status$direnv$cmd_duration$line_break$character";

      username = {
        show_always = true;
        style_user = "bold fg:81";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bold fg:45";
        format = "[@$hostname]($style) ";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold fg:33";
        format = "[$path]($style) ";
      };

      git_branch = {
        symbol = " ";
        style = "bold fg:135";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "fg:135";
        format = "[$all_status$ahead_behind]($style) ";
      };

      # Direnv indicator
      direnv = {
        format = "[$symbol$loaded/$allowed]($style) ";
        symbol = "📁 ";
        style = "bold fg:208";
        disabled = false;
      };

      cmd_duration = {
        min_time = 500;
        style = "fg:250";
        format = "[$duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold fg:82)";
        error_symbol = "[❯](bold fg:196)";
        vicmd_symbol = "[❮](bold fg:214)";
      };
    };
  };
}
