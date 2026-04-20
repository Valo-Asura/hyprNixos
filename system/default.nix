# System configuration
{ hostname, lib, ... }:

{
  imports = [
    ../asuraPc/system/default.nix
  ];

  networking.hostName = hostname;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-substitution-jobs = 64;
    http-connections = 128;
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
