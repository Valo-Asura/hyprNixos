# Program configurations
{ pkgs, ... }:

{
  imports = [
    ./git
    ./terminal
    ./neovim
    ./fastfetch
    ./scripts
  ];
}
