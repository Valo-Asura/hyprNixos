# Hardware Configuration
{ config, lib, ... }:

{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
    graphics.enable = true;
    bluetooth.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      prime = {
        offload.enable = lib.mkForce false;
        sync.enable = lib.mkForce false;
        reverseSync.enable = lib.mkForce false;
      };
    };
  };

  # Broadcom BCM4360 requires proprietary wl (broadcom_sta), not b43/bcma.
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelModules = [ "wl" ];
  boot.blacklistedKernelModules = [
    "b43"
    "b43legacy"
    "ssb"
    "bcma"
    "brcm80211"
    "brcmfmac"
    "brcmsmac"
  ];

  # Avoid switch-time failure when running an older kernel/userspace combo.
  # Start persistenced only when real NVIDIA device node exists.
  systemd.services.nvidia-persistenced.unitConfig.ConditionPathExists = "/dev/nvidia0";
}
