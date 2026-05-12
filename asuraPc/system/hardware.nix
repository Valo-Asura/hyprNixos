# Hardware Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
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
  # Load NVIDIA KMS early so the display stack starts at the panel's native mode
  # instead of briefly falling back to a low-resolution firmware mode.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
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
