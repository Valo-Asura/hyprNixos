# System configuration
{ inputs, hostname, username, ... }:

{
  imports = [
    ../asuraLaptop/system/default.nix
  ];

  # System-wide configuration
  networking.hostName = hostname;
  
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}