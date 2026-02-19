# System Configuration Entry Point
{
  imports = [
    # Hardware (auto-generated, do not modify)
    ./hardware-configuration.nix

    # System Modules
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./locale.nix
    ./display.nix
    ./login.nix
    ./hardware.nix
    ./audio.nix
    ./services.nix
    ./programs.nix
    ./ambxst.nix
    ./packages.nix
    ./environment.nix
    ./theming.nix
    ./browser-theming.nix
    ./maintenance.nix
    ./performance.nix
    ./filesystems.nix
    ./windows-mount-helper.nix
    ./thermal.nix
    ./secrets.nix
    ./fan-control-tools.nix
    ./power-management-tools.nix
  ];
}
