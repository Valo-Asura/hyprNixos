# System configuration
<<<<<<< HEAD
{ inputs, hostname, username, lib, ... }:

{
  imports = [
    ../asuraPc/system/default.nix
=======
{ inputs, hostname, username, ... }:

{
  imports = [
    ../asuraLaptop/system/default.nix
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  ];

  # System-wide configuration
  networking.hostName = hostname;
  
<<<<<<< HEAD
  # Nix daemon settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-substitution-jobs = 64;
    http-connections = 128;
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # BCM4360 requires broadcom-sta (insecure/unmaintained upstream); allow only this package.
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" ];
}
=======
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
