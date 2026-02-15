# Hardware Configuration
{ config, lib, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;
  hardware.i2c.enable = true;

  hardware = {
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
        sync.enable = true;
        offload.enable = lib.mkForce false;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
