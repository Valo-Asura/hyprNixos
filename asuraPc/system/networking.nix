# Networking Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

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

      dns = "systemd-resolved";
    };

    wireless.enable = lib.mkForce false;


  # A slow or reconnecting Archer T6E link should not stall boot.
}
=======
#       ${pkgs.systemd}/bin/resolvectl flush-caches >/dev/null 2>&1 || true
#       ${pkgs.networkmanager}/bin/nmcli general reload >/dev/null 2>&1 || true
#     fi
#   '';
# }
>>>>>>> b5fe558 (init nixos configuration)
