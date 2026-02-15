<<<<<<< HEAD
# VS Code, VSCodium, Kiro, and Windsurf editor defaults
{ lib, pkgs, ... }:

let
  editorSettings = {
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
    "editor.rulers" = [
      80
      120
    ];

    # File settings
    "files.autoSave" = "afterDelay";
    "files.autoSaveDelay" = 1000;
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;

    # Terminal integration
    "terminal.integrated.defaultProfile.linux" = "fish";
    "terminal.integrated.profiles.linux" = {
      fish = {
        path = "${pkgs.fish}/bin/fish";
      };
    };
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

    # Theme
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";

    # Vim settings
    "vim.useSystemClipboard" = true;
    "vim.hlsearch" = true;
    "vim.leader" = "<space>";

    # Telemetry and update noise
    "telemetry.telemetryLevel" = "off";
    "telemetry.enableTelemetry" = false;
    "telemetry.enableCrashReporter" = false;
    "redhat.telemetry.enabled" = false;
    "workbench.enableExperiments" = false;
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
    "update.mode" = "none";

    # Codex extension
    "chatgpt.cliExecutable" = "/run/current-system/sw/bin/codex";
    "chatgpt.openOnStartup" = false;

    # Language specific
    "python.defaultInterpreterPath" = "python3";
    "rust-analyzer.checkOnSave.command" = "clippy";

    # Formatting
    "editor.formatOnSave" = true;
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "explicit";
    };
  };

  windsurfSettings = editorSettings // {
    # The bundled Devin Local binary currently segfaults on this NixOS setup
    # before the ACP handshake. Keep ACP enabled, but do not instantiate the
    # crashing local connectors.
    "windsurf.acp.enabled" = true;
    "windsurf.acp.preferredAgent" = "devin-cloud";
    "windsurf.acp.enabledAgents" = {
      "devin-cli" = false;
      "summary-agent" = false;
      "devin-cloud" = true;
    };
  };

  editorSettingsFile = pkgs.writeText "vscode-user-settings.json" (builtins.toJSON editorSettings);
  windsurfSettingsFile = pkgs.writeText "windsurf-user-settings.json" (builtins.toJSON windsurfSettings);

  commonProfile = {
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
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons
      dracula-theme.theme-dracula
    ];

    userSettings = editorSettings;

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

  # Keep extensions managed, but let the editors own settings.json and
  # keybindings.json so UI changes are writable instead of symlinked to the
  # read-only Nix store.
  mutableCodeProfile = builtins.removeAttrs commonProfile [
    "userSettings"
    "keybindings"
  ];
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default = mutableCodeProfile;
  };

  programs.kiro = {
    enable = true;
    package = pkgs.kiro;
    profiles.default = mutableCodeProfile;
  };

  home.file.".windsurf/acp/registry.json".text = builtins.toJSON {
    version = "0.1.0";
    agents = [ ];
  };

  home.activation.editorMutableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    merge_json_settings() {
      target="$1"
      source="$2"
      target_dir="$(${pkgs.coreutils}/bin/dirname "$target")"
      tmp="$target.tmp"

      ${pkgs.coreutils}/bin/mkdir -p "$target_dir"

      if [ -L "$target" ]; then
        link_target="$(${pkgs.coreutils}/bin/readlink -f "$target")"
        ${pkgs.coreutils}/bin/cp "$link_target" "$tmp"
        ${pkgs.coreutils}/bin/rm -f "$target"
        ${pkgs.coreutils}/bin/mv "$tmp" "$target"
        ${pkgs.coreutils}/bin/chmod u+w "$target"
      fi

      if [ -s "$target" ]; then
        if ! ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" "$source" > "$tmp"; then
          ${pkgs.coreutils}/bin/cp "$source" "$tmp"
        fi
      else
        ${pkgs.coreutils}/bin/cp "$source" "$tmp"
      fi

      ${pkgs.coreutils}/bin/mv "$tmp" "$target"
      ${pkgs.coreutils}/bin/chmod u+w "$target"
    }

    merge_json_settings "$HOME/.config/Code/User/settings.json" "${editorSettingsFile}"
    merge_json_settings "$HOME/.config/VSCodium/User/settings.json" "${editorSettingsFile}"
    merge_json_settings "$HOME/.config/Kiro/User/settings.json" "${editorSettingsFile}"
    merge_json_settings "$HOME/.config/Windsurf/User/settings.json" "${windsurfSettingsFile}"

    vscode_extensions="$HOME/.vscode/extensions"
    vscodium_extensions="$HOME/.vscode-oss/extensions"
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.vscode-oss"
    if [ -L "$vscodium_extensions" ]; then
      current_target="$(${pkgs.coreutils}/bin/readlink "$vscodium_extensions")"
      if [ "$current_target" != "$vscode_extensions" ]; then
        ${pkgs.coreutils}/bin/rm -f "$vscodium_extensions"
      fi
    elif [ -d "$vscodium_extensions" ] && [ -z "$(${pkgs.findutils}/bin/find "$vscodium_extensions" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
      ${pkgs.coreutils}/bin/rmdir "$vscodium_extensions"
    fi

    if [ ! -e "$vscodium_extensions" ] && [ -d "$vscode_extensions" ]; then
      ${pkgs.coreutils}/bin/ln -s "$vscode_extensions" "$vscodium_extensions"
    fi
  '';
=======
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
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
}
