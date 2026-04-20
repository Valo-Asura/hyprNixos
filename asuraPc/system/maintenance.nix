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
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
    optimise.automatic = true;       # periodic store optimisation pass
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Maintenance should never compete with the desktop.
  systemd.services = {
    nix-gc.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
    };
    nix-optimise.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
    };
    fstrim.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };

  # System Updates (disabled for flake-based system)
  system = {
    autoUpgrade.enable = false; # Use 'nix flake update' instead
    stateVersion = "25.11";
  };
}
