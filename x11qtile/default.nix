# default.nix
# X11 Qtile Session Entry Point
{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/session.nix
    ./modules/home.nix
  ];
}
