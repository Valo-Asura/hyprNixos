# VS Code, VSCodium, Kiro, and Windsurf editor defaults
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
}
