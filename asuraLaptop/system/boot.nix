# Boot Configuration
{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = true;
        device = "nodev";
        efiInstallAsRemovable = false;
        theme = ../assets/grub-theme;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest_zen;
  };
}
