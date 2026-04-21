# Hardware Configuration
{ config, lib, pkgs, ... }:

{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
    graphics = {
      enable = true;
      extraPackages = [ pkgs.nvidia-vaapi-driver ];
    };
    bluetooth.enable = true;
    nvidia = {
      modesetting.enable = lib.mkForce true;
      powerManagement.enable = false;
      nvidiaPersistenced = false;
      open = lib.mkForce false;
      nvidiaSettings = true;
      # Pin the older 580 branch explicitly for stability instead of following
      # the moving production/stable aliases, which currently resolve to 595.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      prime = {
        offload.enable = lib.mkForce false;
        sync.enable = lib.mkForce false;
        reverseSync.enable = lib.mkForce false;
      };
    };
  };

  # Broadcom BCM4360 requires proprietary wl (broadcom_sta), not b43/bcma.
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelModules = [
    "wl"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.blacklistedKernelModules = [
    "b43"
    "b43legacy"
    "ssb"
    "bcma"
    "brcm80211"
    "brcmfmac"
    "brcmsmac"
  ];

}
