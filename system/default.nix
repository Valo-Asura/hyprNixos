# System configuration
{
  hostname,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../asuraPc/system/default.nix
    ../x11qtile
  ];

  networking.hostName = hostname;

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-substitution-jobs = 64;
      http-connections = 128;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowInsecurePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "broadcom-sta"
      ];
  };
}
