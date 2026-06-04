# Applications: terminal, launcher, control panels
{ pkgs }:

with pkgs; [
  # Terminal
  kitty
  tmux

  # Launcher
  fuzzel

  # Control panels
  networkmanagerapplet
  blueman
  pwvucontrol
  gradia

  # Icons
  adwaita-icon-theme
  kdePackages.breeze-icons
  hicolor-icon-theme
  papirus-icon-theme
]
