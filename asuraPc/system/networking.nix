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

    firewall = {
      enable = true;
      allowPing = true;
      checkReversePath = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # A slow or reconnecting Archer T6E link should not stall boot.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "false";
}
