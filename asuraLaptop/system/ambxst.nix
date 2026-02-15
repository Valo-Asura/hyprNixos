# Ambxst integration (local flake input)
{ inputs, pkgs, ... }:

{
  imports = [ inputs.ambxst.nixosModules.default ];

  programs.ambxst = {
    enable = true;
    package = inputs.ambxst.packages.${pkgs.stdenv.hostPlatform.system}.Ambxst;
    fonts.enable = true;
  };
}
