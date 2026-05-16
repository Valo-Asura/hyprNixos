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

      # ── Rebuild responsiveness fix ──────────────────────────────────
      # Root cause of desktop freezes during nixos-rebuild:
      #   max-jobs = auto  → 12 parallel build jobs on this 12-thread CPU
      #   cores    = 0     → each job is given ALL cores (also 12)
      # Together this means every core is fully saturated by build
      # workers; the desktop compositor/input gets starved of CPU time.
      #
      # Fix: cap at 6 jobs × 4 cores each. scx_lavd + ananicy handle
      # real-time prioritisation on top. Raise temporarily if needed:
      #   sudo nixos-rebuild switch --option max-jobs 10
      max-jobs = 6;
      cores = 4;

      # Reduce sandbox /dev/shm from the default 50% (~8 GB) to 25% (~4 GB).
      # Heavy Rust/C++ builds can fill shm and cause OOM-adjacent stalls.
      sandbox-dev-shm-size = "25%";

      # Cap substitution parallelism to avoid bandwidth monopoly.
      max-substitution-jobs = 16;

      # Allow builds to use binary cache before falling back to source.
      fallback = true;
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

    # ── Desktop-safe rebuild wrapper ──────────────────────────────────
    # Runs nixos-rebuild at the lowest scheduler priority so the desktop
    # stays responsive during a switch/boot/test.
    # All extra args pass through to nixos-rebuild unchanged.
    #
    # Usage:
    #   nixos-rebuild-safe switch
    #   nixos-rebuild-safe switch --flake /etc/nixos#asuraPc
    (pkgs.writeShellScriptBin "nixos-rebuild-safe" ''
      set -euo pipefail

      echo "[nixos-rebuild-safe] Running rebuild with reduced CPU/IO priority..."
      echo "  max-jobs=6  cores=4  nice=15  ionice=idle"
      echo ""

      exec ${pkgs.util-linux}/bin/ionice -c 3 \
        ${pkgs.coreutils}/bin/nice -n 15 \
        sudo nixos-rebuild "$@" \
          --option max-jobs 6 \
          --option cores 4 \
          --option sandbox-dev-shm-size "25%"
    '')
  ];

  boot.tmp.cleanOnBoot = true;
  services.fstrim.enable = true;

  # Maintenance tasks should never compete with the desktop.
  systemd.services = {
    nix-gc.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      CPUWeight = 10; # yield heavily to interactive tasks
    };
    nix-optimise.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      CPUWeight = 10;
    };
    fstrim.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
    # Give nix-daemon a low cgroup CPU/IO weight so scx_lavd can throttle
    # rebuild workers whenever interactive apps need cores.
    # (default CPUWeight = 100; lower = yields more readily)
    nix-daemon.serviceConfig = {
      CPUWeight = 20;
      IOWeight = 20;
    };
  };

  # System Updates (disabled for flake-based system)
  system = {
    autoUpgrade.enable = false; # Use 'nix flake update' instead
    stateVersion = "25.11";
  };
}
