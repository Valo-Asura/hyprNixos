# System Maintenance Configuration
{ ... }:

{
  # Nix Configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;   # hard-link identical files on every build
      keep-outputs = false;          # don't retain build outputs after GC
      keep-derivations = false;      # don't retain .drv files after GC
    };
    optimise.automatic = true;       # periodic store optimisation pass
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
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