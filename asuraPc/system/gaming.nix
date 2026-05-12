# Gaming and Steam support
{ pkgs, ... }:

{
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = false;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = false;

      gamescopeSession = {
        enable = true;
        args = [
          "--adaptive-sync"
          "--mangoapp"
        ];
      };
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    protonup-qt
    steam-run
  ];
}
