# Shell configuration
{ pkgs, ... }:

{
  imports = [
    ./quotes.nix
  ];

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

<<<<<<< HEAD
=======
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];

>>>>>>> 089bacc (init nixos configuration)
  # ── Shell tools ──────────────────────────────────────────────────────────────

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

  programs.fish = {
    enable = true;

    shellInit = ''
      # Suppress default greeting
      set -U fish_greeting

      # Direnv hook
      direnv hook fish | source

      # Optional shell banner. Leave it off by default so terminals open fast.
      if test "$ASURA_SHOW_SHELL_BANNER" = "1"
        and not set -q __MICROFETCH_RAN
        and not set -q __microfetch_in_subshell
        and status is-interactive
        set -gx __MICROFETCH_RAN 1
        microfetch
        echo
        random-quote
        echo
      end
    '';

    interactiveShellInit = ''
      # Tab: accept autosuggestion if available, else complete
      function __tab_or_accept --description 'Accept autosuggestion or complete'
        set -l sug (commandline -P)
        if test -n "$sug"
          accept-autosuggestion
        else
          commandline -f complete
        end
      end
      bind \t __tab_or_accept

      # Vi-mode convenience bindings
      bind -M insert \cf accept-autosuggestion
      bind -M insert \ce end-of-line
      bind -M insert \cr history-pager
      bind -M insert \cs pager-toggle-search
    '';

    shellAliases = {
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
<<<<<<< HEAD
=======
      cursor  = "cursor";
      zed     = "zeditor";
>>>>>>> 089bacc (init nixos configuration)
      c       = "clear";
      e       = "exit";

      # ── Safety ─────────────────────────────────────────────────────────────
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

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
          bottom
        '';
      };

      # Make a dir and cd into it
      mkcd = {
        description = "Create directory and cd into it";
        body = ''
          mkdir -p $argv[1]
          cd $argv[1]
        '';
      };

      # Detailed system snapshot
      sysinfo = {
        description = "Show system snapshot: info / memory / disk / temps";
        body = ''
          echo "🖥️  System Information"
          echo "===================="
          microfetch
          echo ""
          echo "💾 Memory:"
          free -h
          echo ""
          echo "💿 Disk:"
          df -h / /home 2>/dev/null | tail -n +2
          echo ""
          echo "🌡️  Temps:"
          sensors | grep -E "(Core|Package)" | head -4
        '';
      };

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
          end
        '';
      };
    };
  };

  # ── Starship prompt ───────────────────────────────────────────────────────────

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;   # ms — raised slightly to avoid false timeouts

      format = "$username$hostname$directory$git_branch$git_status$direnv$cmd_duration$line_break$character";

      username = {
        show_always = true;
        style_user  = "bold fg:81";
        format      = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style    = "bold fg:45";
        format   = "[@$hostname]($style) ";
      };

      directory = {
        truncation_length  = 3;
        truncation_symbol  = "…/";
        style              = "bold fg:33";
        format             = "[$path]($style) ";
      };

      git_branch = {
        symbol = " ";
        style  = "bold fg:135";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style  = "fg:135";
        format = "[$all_status$ahead_behind]($style) ";
      };

      direnv = {
        format   = "[$symbol$loaded/$allowed]($style) ";
        symbol   = "📁 ";
        style    = "bold fg:208";
        disabled = false;
      };

      cmd_duration = {
        min_time = 500;
        style    = "fg:250";
        format   = "[$duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold fg:82)";
        error_symbol   = "[❯](bold fg:196)";
        vicmd_symbol   = "[❮](bold fg:214)";
      };
    };
  };
}
