# Desktop applications
{ pkgs, ... }:

{
  imports = [
    ../../../asuraPc/wofi/default.nix
    # Vibeshell/Quickshell is disabled while testing Noctalia v5.
    # ../../../asuraPc/vibeshell/home.nix
  ];

  home.packages = [ pkgs.wofi ];
}
