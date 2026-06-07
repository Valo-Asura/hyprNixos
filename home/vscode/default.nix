# VS Code-like editor defaults
{ lib, pkgs, ... }:

let
  bbenoistQml = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    publisher = "bbenoist";
    name = "qml";
    version = "1.0.0";
    sha256 = "sha256-tphnVlD5LA6Au+WDrLZkAxnMJeTCd3UTyTN1Jelditk=";
  };
  bbenoistNixExtension = "${pkgs.vscode-extensions.bbenoist.nix}/share/vscode/extensions/bbenoist.Nix";
  bbenoistQmlExtension = "${bbenoistQml}/share/vscode/extensions/bbenoist.qml";
  direnvExtension = "${pkgs.vscode-extensions.mkhl.direnv}/share/vscode/extensions/mkhl.direnv";
  gitlensExtension = "${pkgs.vscode-extensions.eamodio.gitlens}/share/vscode/extensions/eamodio.gitlens";
  githubThemeExtension = "${pkgs.vscode-extensions.github.github-vscode-theme}/share/vscode/extensions/github.github-vscode-theme";
  catppuccinIconsExtension = "${pkgs.vscode-extensions.catppuccin.catppuccin-vsc-icons}/share/vscode/extensions/catppuccin.catppuccin-vsc-icons";
  nixIdeExtension = "${pkgs.vscode-extensions.jnoortheen.nix-ide}/share/vscode/extensions/jnoortheen.nix-ide";
  pythonExtension = "${pkgs.vscode-extensions.ms-python.python}/share/vscode/extensions/ms-python.python";

  commonProfile = {
    extensions = with pkgs.vscode-extensions; [
      # Direnv support
      mkhl.direnv

      # Nix support
      bbenoist.nix
      jnoortheen.nix-ide

      # QML support
      bbenoistQml

      # General development
      ms-python.python

      # Git integration
      eamodio.gitlens

      # Themes and UI
      github.github-vscode-theme
      catppuccin.catppuccin-vsc-icons
    ];

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
    "extensions"
    "userSettings"
    "keybindings"
  ];
in
{
  home.activation.repairEditorCodexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for editor in Code Kiro Cursor Antigravity; do
      settings="$HOME/.config/$editor/User/settings.json"
      if [ -f "$settings" ]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.jq}/bin/jq \
          '.["workbench.colorTheme"] = "GitHub Dark Default"
           | .["workbench.iconTheme"] = "catppuccin-mocha"' \
          "$settings" > "$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$settings"
      fi

      if [ "$editor" != Cursor ] && [ "$editor" != Antigravity ] && [ -f "$settings" ] && ${pkgs.jq}/bin/jq -e '.["chatgpt.cliExecutable"] == "/run/current-system/sw/bin/codex"' "$settings" >/dev/null 2>&1; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.jq}/bin/jq 'del(.["chatgpt.cliExecutable"])' "$settings" > "$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$settings"
      fi

      extensions_dir=""
      case "$editor" in
        Code) extensions_dir="$HOME/.vscode/extensions" ;;
        Kiro) extensions_dir="$HOME/.kiro/extensions" ;;
        Cursor) extensions_dir="$HOME/.cursor/extensions" ;;
        Antigravity) extensions_dir="$HOME/.antigravity/extensions" ;;
      esac
      ${pkgs.coreutils}/bin/mkdir -p "$extensions_dir"

      for ext_path in "$extensions_dir"/*; do
        if [ ! -e "$ext_path" ] && [ ! -L "$ext_path" ]; then
          continue
        fi
        if [ -L "$ext_path" ] && [ ! -e "$ext_path" ]; then
          ${pkgs.coreutils}/bin/rm -f "$ext_path"
          continue
        fi
        if [ -d "$ext_path" ] && [ ! -f "$ext_path/package.json" ]; then
          ${pkgs.coreutils}/bin/rm -rf "$ext_path"
        fi
      done

      ${pkgs.findutils}/bin/find "$extensions_dir" -maxdepth 1 -type d \( \
        -iname 'catppuccin.catppuccin-vsc-*' -o \
        -iname 'dracula-theme.theme-dracula-*' -o \
        -iname 'pkief.material-icon-theme-*' -o \
        -iname 'vscode-icons-team.vscode-icons-*' \
      \) -exec ${pkgs.coreutils}/bin/rm -rf {} +

      ${pkgs.coreutils}/bin/ln -sfn ${bbenoistNixExtension} "$extensions_dir/bbenoist.Nix"
      ${pkgs.coreutils}/bin/ln -sfn ${bbenoistQmlExtension} "$extensions_dir/bbenoist.qml"
      ${pkgs.coreutils}/bin/ln -sfn ${direnvExtension} "$extensions_dir/mkhl.direnv"
      ${pkgs.coreutils}/bin/ln -sfn ${gitlensExtension} "$extensions_dir/eamodio.gitlens"
      ${pkgs.coreutils}/bin/ln -sfn ${githubThemeExtension} "$extensions_dir/github.github-vscode-theme"
      ${pkgs.coreutils}/bin/ln -sfn ${catppuccinIconsExtension} "$extensions_dir/catppuccin.catppuccin-vsc-icons"
      ${pkgs.coreutils}/bin/ln -sfn ${nixIdeExtension} "$extensions_dir/jnoortheen.nix-ide"
      ${pkgs.coreutils}/bin/ln -sfn ${pythonExtension} "$extensions_dir/ms-python.python"

      # VS Code caches extension locations here. Removing it clears stale
      # entries that point at old Nix-managed symlinks; VS Code regenerates it.
      ${pkgs.coreutils}/bin/rm -f "$extensions_dir/extensions.json"

      # Some bundled extensions copy helper files from the immutable Nix store,
      # then update them in place later. Keep their mutable storage writable.
      mutable_storage="$HOME/.config/$editor/User/globalStorage"
      if [ -d "$mutable_storage" ]; then
        ${pkgs.findutils}/bin/find "$mutable_storage" -path '*/github.copilot-chat/*' \
          -exec ${pkgs.coreutils}/bin/chmod u+rwX {} +
      fi
    done
  '';

  programs.vscode = {
    enable = true;
    # VS Code itself stays system-level; Home Manager only owns its user config.
    package = null;
    profiles.default = mutableCodeProfile;
  };

  programs.kiro = {
    enable = true;
    package = pkgs.kiro;
    profiles.default = mutableCodeProfile;
  };
}
