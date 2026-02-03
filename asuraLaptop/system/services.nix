# System Services Configuration
{ pkgs, ... }:

{
  services = {
    blueman.enable = true;
    dbus.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    upower.enable = true;
    printing.enable = true;
  };

  # Enable dconf for GNOME applications
  programs.dconf.enable = true;

  # Enable accessibility services for ambxst keyboard input
  services.gnome.at-spi2-core.enable = true;
  
  # Compile GSettings schemas properly
  services.dbus.packages = with pkgs; [ 
    gsettings-desktop-schemas 
    gtk3 
    gtk4 
  ];

  # Systemd User Services
  systemd.user.services.udiskie = {
    description = "Udiskie Daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-notify";
      Restart = "always";
      RestartSec = 10;
    };
  };
}