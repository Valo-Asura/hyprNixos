# Vibeshell integration (local flake input)
{ inputs, pkgs, ... }:

{
  imports = [ inputs.vibeshell.nixosModules.default ];

  programs.vibeshell = {
    enable = true;
    package = inputs.vibeshell.packages.${pkgs.stdenv.hostPlatform.system}.Vibeshell;
    fonts.enable = true;
  };
}
