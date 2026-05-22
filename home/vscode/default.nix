# VS Code-like editor defaults
{ lib, pkgs, ... }:

let
  githubThemeExtension = "${pkgs.vscode-extensions.github.github-vscode-theme}/share/vscode/extensions/github.github-vscode-theme";
  catppuccinIconsExtension = "${pkgs.vscode-extensions.catppuccin.catppuccin-vsc-icons}/share/vscode/extensions/catppuccin.catppuccin-vsc-icons";

  commonProfile = {
    extensions = with pkgs.vscode-extensions; [
      # Direnv support
      mkhl.direnv

      # Nix support
      bbenoist.nix
      jnoortheen.nix-ide

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
      ${pkgs.findutils}/bin/find "$extensions_dir" -maxdepth 1 -type d \( \
        -iname 'catppuccin.catppuccin-vsc-*' -o \
        -iname 'dracula-theme.theme-dracula-*' -o \
        -iname 'pkief.material-icon-theme-*' -o \
        -iname 'vscode-icons-team.vscode-icons-*' \
      \) -exec ${pkgs.coreutils}/bin/rm -rf {} +

      ${pkgs.coreutils}/bin/ln -sfn ${githubThemeExtension} "$extensions_dir/github.github-vscode-theme"
      ${pkgs.coreutils}/bin/ln -sfn ${catppuccinIconsExtension} "$extensions_dir/catppuccin.catppuccin-vsc-icons"

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
