# Boot Configuration
{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      timeout = 5;
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
  };
}
