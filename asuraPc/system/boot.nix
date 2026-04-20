# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
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
      # Performance
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "cryptomgr.notests"
    ];
  };
}
