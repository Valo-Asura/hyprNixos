# System Maintenance Configuration
{ pkgs, ... }:

{
  # Nix Configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;   # hard-link identical files on every build
      keep-outputs = false;          # don't retain build outputs after GC
      keep-derivations = false;      # don't retain .drv files after GC
      min-free = 2 * 1024 * 1024 * 1024;
      max-free = 8 * 1024 * 1024 * 1024;
    };
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
    optimise.automatic = true;       # periodic store optimisation pass
    optimise.dates = [ "daily" ];
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
      persistent = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-storage-clean" ''
      set -euo pipefail

      days="''${1:-3d}"
      echo "User GC: deleting generations older than $days"
      nix-collect-garbage --delete-older-than "$days"

      if [ -L /etc/nixos/result ]; then
        echo "Removing stale /etc/nixos/result GC root"
        rm -f /etc/nixos/result
      fi

      if command -v sudo >/dev/null 2>&1; then
        echo "System GC: sudo may ask for your password"
        sudo nix-collect-garbage --delete-older-than "$days"
      fi

      echo "Optimising store links: sudo may ask for your password"
      sudo nix-store --optimise
    '')
  ];

  boot.tmp.cleanOnBoot = true;
  services.fstrim.enable = true;

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
