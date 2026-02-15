# Networking Configuration
{ ... }:

{
  networking = {
    hostName = "nixos";

    # NetworkManager with iwd backend (faster, more reliable than wpa_supplicant)
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = false;       # Never let NM toggle WiFi power save
        scanRandMacAddress = true;
      };
      # Use systemd-resolved for DNS
      dns = "systemd-resolved";
    };

    # Enable iwd
    wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = false;  # let NM handle IP
          AddressRandomization = "once";
        };
        Settings = {
          AutoConnect = true;
        };
      };
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
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [
      "1.1.1.1"       # Cloudflare
      "8.8.8.8"       # Google
      "1.0.0.1"
      "8.8.4.4"
    ];
    dnsovertls = "opportunistic";
  };
}