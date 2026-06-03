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
    ./local-ai.nix
    ./programs.nix
    ./gaming.nix
    # Vibeshell/Quickshell is disabled while testing Noctalia v5.
    # ./vibeshell.nix
    ./noctalia.nix
    ./skwd-wall.nix
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
    ./secrets.nix
    ./fan-control-tools.nix
    ./power-management-tools.nix
  ];
}
