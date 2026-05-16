# VS Code and Kiro editor defaults
{ lib, pkgs, ... }:

let
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
    for editor in Code Kiro; do
      settings="$HOME/.config/$editor/User/settings.json"
      if [ -f "$settings" ] && ${pkgs.jq}/bin/jq -e '.["chatgpt.cliExecutable"] == "/run/current-system/sw/bin/codex"' "$settings" >/dev/null 2>&1; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.jq}/bin/jq 'del(.["chatgpt.cliExecutable"])' "$settings" > "$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$settings"
      fi

      registers_dir="$HOME/.config/$editor/User/globalStorage/vscodevim.vim"
      ${pkgs.coreutils}/bin/mkdir -p "$registers_dir"
      ${pkgs.coreutils}/bin/touch "$registers_dir/.registers"
    done
  '';

  programs.kiro = {
    enable = true;
    package = pkgs.kiro;
    profiles.default = mutableCodeProfile;
  };
}
