# Home Manager configuration
{ inputs, pkgs, ... }:

{
  imports = [
    ./programs
    ./desktop
    ./shell
    ./vscode
    ./microfetch
    ./templates
  ];

  home = {
    username = "asura";
    homeDirectory = "/home/asura";
    stateVersion = "25.11";
  };

  xdg.userDirs = {
    enable = true;
    # Keep the pre-26.05 behavior explicit and silence the Home Manager warning.
    setSessionVariables = true;
  };

  # Vibeshell owns the network tray/control surface. Keep nm-connection-editor
  # available, but prevent nm-applet's legacy tray autostart warnings.
  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=NetworkManager Applet
    Hidden=true
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
