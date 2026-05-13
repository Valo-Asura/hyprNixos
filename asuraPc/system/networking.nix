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
        # Archer T6E / AC1300 is Broadcom BCM4360-class hardware.
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

  # wpa_supplicant must be present so NetworkManager's wpa_supplicant backend
  # can D-Bus activate it for the Broadcom BCM4360 wifi card.
  environment.systemPackages = [ pkgs.wpa_supplicant ];

  # Create the D-Bus activatable wpa_supplicant service that NetworkManager expects.
  systemd.services.wpa_supplicant = {
    description = "WPA Supplicant (for NetworkManager)";
    wantedBy = [ ];
    serviceConfig = {
      ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -u -s";
      Restart = "on-failure";
    };
  };

  # A slow or reconnecting Archer T6E link should not stall boot.
  systemd.services.NetworkManager-wait-online = {
    enable = false;
    wantedBy = lib.mkForce [ ];
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "false";
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
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
      "b43legacy"
      "bcma"
      "ssb"
      "brcm80211"
      "brcmsmac"
      "brcmfmac"
    ];
  };

  # Remove stale tunnel profiles/routes from older generations. No VPN or
  # WireGuard service is declared by this config.
  system.activationScripts.removeStaleNetworkTunnels.text = ''
    if ${pkgs.systemd}/bin/systemctl -q is-active NetworkManager.service; then
      ${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE connection show --active \
        | ${pkgs.gawk}/bin/awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
        | while IFS= read -r name; do
          [ -n "$name" ] || continue
          ${pkgs.networkmanager}/bin/nmcli connection down "$name" >/dev/null 2>&1 || true
        done

      ${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE connection show \
        | ${pkgs.gawk}/bin/awk -F: '$2=="wireguard" || $2=="vpn"{print $1}' \
        | while IFS= read -r name; do
          [ -n "$name" ] || continue
          ${pkgs.networkmanager}/bin/nmcli connection delete "$name" >/dev/null 2>&1 || true
        done

      ${pkgs.iproute2}/bin/ip route show \
        | ${pkgs.gawk}/bin/awk '/ dev (wg|tun|tap)[0-9A-Za-z_.-]*/ { print }' \
        | while IFS= read -r route; do
          [ -n "$route" ] || continue
          ${pkgs.iproute2}/bin/ip route del $route >/dev/null 2>&1 || true
        done

      ${pkgs.systemd}/bin/resolvectl flush-caches >/dev/null 2>&1 || true
      ${pkgs.networkmanager}/bin/nmcli general reload >/dev/null 2>&1 || true
    fi
  '';
}
