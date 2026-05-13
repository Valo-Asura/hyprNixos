# Networking Configuration
{ config, lib, ... }:

{
  networking = {
    hostName = "nixos";

    networkmanager = {
      enable = true;

      wifi = {
        backend = "wpa_supplicant";
        powersave = false;
        scanRandMacAddress = false;
      };
    };

    wireless.enable = false;
  };

  nixpkgs.config = {
    allowUnfree = true;

    allowInsecurePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "broadcom-sta"
      ];
  };

  boot = {
    kernelModules = [ "wl" ];

    extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];

    blacklistedKernelModules = [
      "b43"
      "bcma"
      "ssb"
      "brcmsmac"
      "brcmfmac"
    ];
  };
}
