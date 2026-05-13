# Networking Configuration
{ lib, pkgs, ... }:

{
  networking = {
    hostName = "nixos";

    # NetworkManager with wpa_supplicant backend (required for BCM4360 wl driver)
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        powersave = false;       # Never let NM toggle WiFi power save
        scanRandMacAddress = false;
      };
    };
};
    # Firewall — allow outbound, block unsolicited inbound
  #   firewall = {
  #     enable = true;
  #     allowPing = true;
  #     checkReversePath = true;
  #     allowedTCPPorts = [ ];      # add ports as needed
  #     allowedUDPPorts = [ ];
  #   };
  # };

  # A flaky Wi-Fi/USB-tether link should not hold the whole boot for a minute.
  # systemd.services.NetworkManager-wait-online = {
  #   enable = false;
  #   wantedBy = lib.mkForce [ ];
  # };

  # systemd-resolved for fast DNS with caching
  # services.resolved = {
  #   enable = true;
  #   settings.Resolve = {
  #     DNSSEC = "allow-downgrade";
  #     DNSOverTLS = "false";
  #     FallbackDNS = [
  #       "1.1.1.1" # Cloudflare
  #       "8.8.8.8" # Google
  #       "1.0.0.1"
  #       "8.8.4.4"
  #     ];
  #   };
  # };

#   system.activationScripts.removeStaleNetworkTunnels.text = ''
#     if ${pkgs.systemd}/bin/systemctl -q is-active NetworkManager.service; then
#       ${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE connection show --active \
#         | ${pkgs.gawk}/bin/awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
#         | while IFS= read -r name; do
#           [ -n "$name" ] || continue
#           ${pkgs.networkmanager}/bin/nmcli connection down "$name" >/dev/null 2>&1 || true
#         done

#       ${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE connection show \
#         | ${pkgs.gawk}/bin/awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
#         | while IFS= read -r name; do
#           [ -n "$name" ] || continue
#           ${pkgs.networkmanager}/bin/nmcli connection delete "$name" >/dev/null 2>&1 || true
#         done

#       ${pkgs.systemd}/bin/resolvectl flush-caches >/dev/null 2>&1 || true
#       ${pkgs.networkmanager}/bin/nmcli general reload >/dev/null 2>&1 || true
#     fi
#   '';
# }
