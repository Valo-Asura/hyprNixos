# Program configurations
{ pkgs, ... }:

{
  imports = [
    ./git
    ./terminal
    ./scripts
    ./openclaw.nix
  ];
}
