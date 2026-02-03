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

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
