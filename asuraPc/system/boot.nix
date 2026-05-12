# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
  preferSignedBootEntry = pkgs.writeShellScript "prefer-signed-boot-entry" ''
    set -euo pipefail

    if [ ! -d /sys/firmware/efi/efivars ]; then
      exit 0
    fi

    status="$(${pkgs.efibootmgr}/bin/efibootmgr 2>/dev/null || true)"
    if [ -z "$status" ]; then
      exit 0
    fi

    current_order="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^BootOrder: //p' | ${pkgs.coreutils}/bin/head -n1)"

    if [ -z "$linux_entry" ] || [ -z "$current_order" ]; then
      exit 0
    fi

    rest="$(printf '%s\n' "$current_order" \
      | ${pkgs.gawk}/bin/awk -v linux="$linux_entry" -v windows="$windows_entry" '
        BEGIN { RS=","; ORS="" }
        $0 != linux && $0 != windows && $0 != "" {
          if (out != "") out = out ","
          out = out $0
        }
        END { print out }
      ')"

    new_order="$linux_entry"
    if [ -n "$windows_entry" ]; then
      new_order="$new_order,$windows_entry"
    fi
    if [ -n "$rest" ]; then
      new_order="$new_order,$rest"
    fi

    if [ "$new_order" != "$current_order" ]; then
      ${pkgs.efibootmgr}/bin/efibootmgr -o "$new_order" || true
    fi
  '';
in
{
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
        rebootForBitlocker = true;
      };

      grub.enable = false;
      limine.enable = false;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = pkiBundle;
    };

    # Follow the newest kernel packaged by nixpkgs while keeping
    # NVIDIA/Broadcom module versions aligned with that kernel.
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
      "video=DP-1:1920x1080@165"
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

  system.activationScripts.preferSignedBootEntry = {
    text = ''
      ${preferSignedBootEntry}
    '';
  };

  # Windows lives on a separate ESP on this machine. Mirror its boot manager
  # onto the NixOS ESP so systemd-boot/Lanzaboote can show it in the menu.
  system.activationScripts.syncWindowsBootEntry = {
      fi
    '';
  };
}
