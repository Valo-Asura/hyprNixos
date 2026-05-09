# Declarative VPN scaffold
{ lib, pkgs, ... }:

let
  # Disabled until real WireGuard peer details and a private key secret exist.
  enableWireGuard = false;
  profileName = "asura-wg0";
  interfaceName = "wg0";
  privateKeyFile = "/run/secrets/WIREGUARD_PRIVATE_KEY";
in
{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  networking.networkmanager.ensureProfiles = lib.mkIf enableWireGuard {
    profiles.${profileName} = {
      connection = {
        id = profileName;
        type = "wireguard";
        interface-name = interfaceName;
        autoconnect = "false";
        permissions = "";
      };

      wireguard = {
        private-key-flags = "2";
        peer-routes = "true";
        mtu = "1420";
      };

      "wireguard-peer.placeholder-public-key" = {
        endpoint = "vpn.example.invalid:51820";
        allowed-ips = "0.0.0.0/0;::/0;";
        persistent-keepalive = "25";
      };

      ipv4 = {
        method = "manual";
        address1 = "10.64.0.2/32";
        dns = "1.1.1.1;1.0.0.1;";
        never-default = "false";
      };

      ipv6 = {
        method = "ignore";
      };
    };

    secrets.entries = [
      {
        matchId = profileName;
        matchType = "wireguard";
        matchSetting = "wireguard";
        key = "private-key";
        file = privateKeyFile;
      }
    ];
  };
}
