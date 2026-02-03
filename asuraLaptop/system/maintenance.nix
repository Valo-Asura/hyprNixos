# System Maintenance Configuration
{ ... }:

{
  # Nix Configuration
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System Updates (disabled for flake-based system)
  system = {
    autoUpgrade.enable = false; # Use 'nix flake update' instead
    stateVersion = "25.11";
  };
}