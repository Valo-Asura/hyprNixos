# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
in
{
  warnings = [ ];

  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
    tpm2-tools
  ];

  boot = {
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      stage1Greeting = "";
    };

    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 12;

      systemd-boot = {
        enable = lib.mkForce false;
        editor = false;
        consoleMode = "max";
        configurationLimit = 8;
      };

      grub.enable = false;
      limine.enable = false;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = pkiBundle;
    };
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      # Performance
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "cryptomgr.notests"
    ];
  };

  # Optional activation-script: create sbctl keys automatically
  # Trigger file: /etc/nixos/enable-sbctl-auto-create (must be created manually)
  system.activationScripts.createSbctlKeys = {
    text = ''
      # Only run when the trigger file exists — this avoids accidental key creation
      if [ -f /etc/nixos/enable-sbctl-auto-create ]; then
        if [ ! -d ${pkiBundle} ]; then
          echo "Auto-creating Secure Boot keys (sbctl)..."
          ${pkgs.sbctl}/bin/sbctl create-keys || true
        else
          echo "sbctl key bundle already exists at ${pkiBundle}; skipping creation."
        fi
      fi
    '';
  };
}
