# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
  windowsEspUuid = "32EC-CB64";
  windowsEspMountPoint = "/run/systemd-boot-windows-esp";
  secureBootFiles = [
    "${pkiBundle}/GUID"
    "${pkiBundle}/keys/db/db.key"
    "${pkiBundle}/keys/db/db.pem"
    "${pkiBundle}/keys/KEK/KEK.key"
    "${pkiBundle}/keys/KEK/KEK.pem"
    "${pkiBundle}/keys/PK/PK.key"
    "${pkiBundle}/keys/PK/PK.pem"
  ];
  secureBootReady = lib.all builtins.pathExists secureBootFiles;
in
{
  warnings = lib.optionals (!secureBootReady) [
    "Secure Boot staging mode: ${pkiBundle} does not contain signing keys yet. This build installs plain systemd-boot first. Run 'sudo sbctl create-keys' and rebuild again to enable Lanzaboote."
  ];

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

      # Stage 1: no key bundle yet -> migrate from Limine to plain systemd-boot.
      # Stage 2: keys exist -> switch to Lanzaboote and prepare Secure Boot
      # enrollment while keeping Microsoft keys for Windows 11 compatibility.
      systemd-boot = {
        enable = lib.mkForce (!secureBootReady);
        editor = false;
        consoleMode = "max";
        configurationLimit = 8;
        extraEntries."windows.conf" = ''
          title Windows 11
          efi /EFI/Microsoft/Boot/Bootmgfw.efi
          sort-key o_windows
        '';
        extraInstallCommands = ''
          # Robust Windows EFI sync:
          # Try configured UUID first, then scan common disk symlinks (/dev/disk/by-uuid, by-label, by-partuuid).
          # Backup any existing copy to /var/lib/esp-backups before replacing.
          try_mount_and_copy() {
            dev="$1"
            ${pkgs.coreutils}/bin/mkdir -p ${windowsEspMountPoint}
            if ${pkgs.util-linux}/bin/mount -o ro "$dev" ${windowsEspMountPoint}; then
              if [ -d ${windowsEspMountPoint}/EFI/Microsoft ]; then
                ${pkgs.coreutils}/bin/mkdir -p /boot/EFI
                if [ -d /boot/EFI/Microsoft ]; then
                  ts=$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)
                  ${pkgs.coreutils}/bin/mkdir -p /var/lib/esp-backups
                  ${pkgs.coreutils}/bin/mv /boot/EFI/Microsoft /var/lib/esp-backups/Microsoft.$ts || true
                fi
                ${pkgs.coreutils}/bin/cp -a ${windowsEspMountPoint}/EFI/Microsoft /boot/EFI/
                ${pkgs.util-linux}/bin/umount ${windowsEspMountPoint}
                return 0
              fi
              ${pkgs.util-linux}/bin/umount ${windowsEspMountPoint}
            fi
            return 1
          }

          if [ -e /dev/disk/by-uuid/${windowsEspUuid} ]; then
            if try_mount_and_copy "/dev/disk/by-uuid/${windowsEspUuid}"; then
              echo "Windows EFI copied from UUID ${windowsEspUuid}"
            else
              echo "warning: failed to copy from /dev/disk/by-uuid/${windowsEspUuid}" >&2
            fi
          else
            found=0
            for dev in /dev/disk/by-uuid/* /dev/disk/by-label/* /dev/disk/by-partuuid/*; do
              [ -e "$dev" ] || continue
              realdev=$(${pkgs.coreutils}/bin/readlink -f "$dev")
              if try_mount_and_copy "$realdev"; then
                echo "Windows EFI copied from $dev ($realdev)"
                found=1
                break
              fi
            done
            if [ "$found" -eq 0 ]; then
              echo "warning: No Windows EFI found in scanned disks; skipping Windows boot entry sync" >&2
            fi
          fi
        '';
      };

      grub.enable = false;
      limine.enable = false;
    };

    lanzaboote = lib.mkIf secureBootReady {
      enable = true;
      pkiBundle = pkiBundle;
      autoEnrollKeys = {
        enable = true;
      };
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
