# Boot Configuration
{ pkgs, ... }:

{
  boot = {
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      stage1Greeting = "";
    };
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      timeout = 3;
      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        enableEditor = false;
        style = {
          wallpapers = [ ../assets/grub-theme/background.png ];
          wallpaperStyle = "stretched";
          interface.helpHidden = true;
        };
        extraEntries = ''
          /Windows (EFI disk 1)
            protocol: efi
            path: hdd(1:1):/EFI/Microsoft/Boot/bootmgfw.efi
            comment: If this entry does not boot, try the next Windows entry

          /Windows (EFI disk 2)
            protocol: efi
            path: hdd(2:1):/EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };
      grub.enable = false;
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
      "mitigations=off"
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "tsc=reliable"            # skip TSC calibration on Intel
      "cryptomgr.notests"       # skip crypto self-tests at boot
    ];
  };
}
