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
        scanRandMacAddress = true;
      };
      # Use systemd-resolved for DNS
      dns = "systemd-resolved";
    };

    # Firewall — allow outbound, block unsolicited inbound
    firewall = {
      enable = true;
      allowPing = true;
      checkReversePath = true;
      allowedTCPPorts = [ ];      # add ports as needed
      allowedUDPPorts = [ ];
    };
  };

  # A flaky Wi-Fi/USB-tether link should not hold the whole boot for a minute.
  systemd.services.NetworkManager-wait-online = {
    enable = false;
    wantedBy = lib.mkForce [ ];
  };

  # systemd-resolved for fast DNS with caching
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "false";
      FallbackDNS = [
        "1.1.1.1" # Cloudflare
        "8.8.8.8" # Google
        "1.0.0.1"
        "8.8.4.4"
      ];
    };
  };

  systemd.services.remove-vpn-networkmanager-profiles = {
    description = "Remove stale NetworkManager VPN and WireGuard profiles";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      gawk
      networkmanager
      systemd
    ];
    script = ''
      set -u

      nmcli -t -f NAME,TYPE connection show --active \
        | awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
        | while IFS= read -r name; do
          [ -n "$name" ] || continue
          nmcli connection down "$name" >/dev/null 2>&1 || true
        done

      nmcli -t -f NAME,TYPE connection show \
        | awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
        | while IFS= read -r name; do
          [ -n "$name" ] || continue
          nmcli connection delete "$name" >/dev/null 2>&1 || true
        done

      resolvectl flush-caches >/dev/null 2>&1 || true
      nmcli general reload >/dev/null 2>&1 || true
    '';
  };
}
