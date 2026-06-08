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
      capSysNice = false;
    };
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "steam-safe" ''
      set -euo pipefail
      cd "$HOME"
      exec ${util-linux}/bin/setpriv --ambient-caps -all --inh-caps -all /run/current-system/sw/bin/steam "$@"
    '')
    gamescope
    mangohud
    protonup-qt
    steam-run
  ];
}
