# System Configuration Entry Point
{
  imports = [
    # Hardware (auto-generated, do not modify)
    ./hardware-configuration.nix

    # System Modules
    ./boot.nix
    ./kernel-cachyos.nix
    ./networking.nix
    ./users.nix
    ./locale.nix
    ./display.nix
    ./login.nix
    ./hardware.nix
    ./audio.nix
    ./services.nix
    ./android.nix
    ./mysql.nix
    ./virtual-machines.nix
    ./programs.nix
    ./gaming.nix
    ./vibeshell.nix
    # Noctalia is disabled; current generated config is backed up outside HM.
    # ./noctalia.nix
    ./packages.nix
    ./environment.nix
    ./theming.nix
    ./browser-theming.nix
    ./maintenance.nix
    ./performance.nix
    ./desktop-performance.nix
    ./filesystems.nix
    ./windows-mount-helper.nix
    ./thermal.nix
    ./fan-control-tools.nix
    ./power-management-tools.nix
  ];
}
