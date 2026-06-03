# Noctalia v5 shell integration.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  wallpaper = builtins.toString ../assets/sans.png;
  noctaliaSafeLock = pkgs.writeShellScriptBin "noctalia-safe-lock" ''
    set -euo pipefail

    if ${noctaliaPackage}/bin/noctalia msg session lock >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pkgs.hyprlock}/bin/hyprlock "$@"
  '';
in
{
  # Upstream cache for Noctalia v5. The flake input intentionally does not
  # follow this system's nixpkgs so these substitutes can be used.
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  environment.systemPackages = [
    noctaliaPackage
    noctaliaSafeLock
  ];

  services = {
    # Noctalia's power-profile UI requires tuned or power-profiles-daemon.
    # This is scoped here so removing this module restores the existing TLP
    # configuration from thermal.nix.
    tlp.enable = lib.mkForce false;
    upower.enable = lib.mkDefault true;
    tuned.enable = true;
  };

  networking.networkmanager.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;

  home-manager.users.asura = {
    imports = [
      inputs.noctalia.homeModules.default
    ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = noctaliaPackage;

      settings = {
        shell = {
          launch_apps_as_systemd_services = true;
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };

        wallpaper = {
          # skwd-wall owns wallpaper rendering; keep Noctalia's wallpaper layer
          # disabled while still giving the picker a stable default image.
          enabled = false;
          default.path = wallpaper;
        };
      };
    };
  };
}
