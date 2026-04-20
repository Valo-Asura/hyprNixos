# Networking Configuration
{ ... }:

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
      allowedTCPPorts = [ ];      # add ports as needed
      allowedUDPPorts = [ ];
    };
  };

  # systemd-resolved for fast DNS with caching
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      Domains = [ "~." ];
      FallbackDNS = [
        "1.1.1.1"       # Cloudflare
        "8.8.8.8"       # Google
        "1.0.0.1"
        "8.8.4.4"
      ];
      DNSOverTLS = "opportunistic";
    };
  };
}
