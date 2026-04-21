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
          if [ -e /dev/disk/by-uuid/${windowsEspUuid} ]; then
            ${pkgs.coreutils}/bin/mkdir -p ${windowsEspMountPoint}
            if ${pkgs.util-linux}/bin/mount -o ro /dev/disk/by-uuid/${windowsEspUuid} ${windowsEspMountPoint}; then
              if [ -d ${windowsEspMountPoint}/EFI/Microsoft ]; then
                ${pkgs.coreutils}/bin/mkdir -p /boot/EFI
                ${pkgs.coreutils}/bin/rm -rf /boot/EFI/Microsoft
                ${pkgs.coreutils}/bin/cp -r ${windowsEspMountPoint}/EFI/Microsoft /boot/EFI/
              else
                echo "warning: Windows ESP mounted but /EFI/Microsoft was not found" >&2
              fi
              ${pkgs.util-linux}/bin/umount ${windowsEspMountPoint}
            else
              echo "warning: failed to mount Windows ESP ${windowsEspUuid}" >&2
            fi
          else
            echo "warning: Windows ESP ${windowsEspUuid} not found; skipping Windows boot entry sync" >&2
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
}
