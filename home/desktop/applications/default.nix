# Desktop applications
{ pkgs, ... }:

{
  imports = [
    ../../../asuraPc/wofi/default.nix
    ../../../asuraPc/vibeshell/home.nix
  ];

  home.packages = [ pkgs.wofi ];
}
