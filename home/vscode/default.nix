# VSCode/Kiro Configuration
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.kiro;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Direnv support
        mkhl.direnv

        # Nix support
        bbenoist.nix
        jnoortheen.nix-ide

        # General development
        redhat.vscode-yaml
        ms-python.python
        rust-lang.rust-analyzer

        # Git integration
        eamodio.gitlens

        # Productivity
        vscodevim.vim

        # Themes and UI
        pkief.material-icon-theme
        github.github-vscode-theme
      ];

      userSettings = {
        # Direnv integration
        "direnv.restart.automatic" = true;
        "direnv.status.showOnStatusBar" = true;

        # Editor settings
        "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', monospace";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "editor.wordWrap" = "on";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [ 80 120 ];

        # File settings
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        # Terminal integration
        "terminal.integrated.shell.linux" = "${pkgs.fish}/bin/fish";
        "terminal.integrated.fontFamily" = "'JetBrains Mono', monospace";
        "terminal.integrated.fontSize" = 13;

        # Git settings
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;

        # Nix settings
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixfmt";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
        };

        # Theme (Stylix-managed)
        "workbench.iconTheme" = "material-icon-theme";

        # Vim settings
        "vim.useSystemClipboard" = true;
        "vim.hlsearch" = true;
        "vim.leader" = "<space>";

        # Performance
        "extensions.autoUpdate" = false;
        "telemetry.telemetryLevel" = "off";

        # Language specific
        "python.defaultInterpreterPath" = "python3";
        "rust-analyzer.checkOnSave.command" = "clippy";

        # Formatting
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
      };

      keybindings = [
        {
          "key" = "ctrl+shift+t";
          "command" = "workbench.action.terminal.new";
        }
        {
          "key" = "ctrl+shift+`";
          "command" = "workbench.action.terminal.toggleTerminal";
        }
      ];
    };
  };
}
