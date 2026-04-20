# Interactive desktop performance
{ lib, pkgs, ... }:

let
  warmTargets = [
    "${pkgs.brave}"
    "${pkgs.firefox}"
    "${pkgs.google-chrome}"
    "${pkgs.vscode}"
    "${pkgs.kiro}"
  ];
  desktopCacheWarm = pkgs.writeShellScript "desktop-cache-warm" ''
    set -euo pipefail

    min_available_kib=$((8 * 1024 * 1024))
    available_kib="$(awk '/MemAvailable/ { print $2 }' /proc/meminfo)"

    if [ -z "$available_kib" ] || [ "$available_kib" -lt "$min_available_kib" ]; then
      exit 0
    fi

    exec ${pkgs.vmtouch}/bin/vmtouch -q -t -f -m 64M \
      ${lib.concatMapStringsSep " \\\n      " lib.escapeShellArg warmTargets}
  '';
in
{
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraTypes = [
      {
        type = "InteractiveDesktop";
        nice = -6;
        ioclass = "best-effort";
        ionice = 0;
        latency_nice = -6;
      }
      {
        type = "DesktopHelper";
        nice = 12;
        ioclass = "idle";
        sched = "idle";
        latency_nice = 8;
      }
    ];
    extraRules = [
      { name = "brave"; type = "InteractiveDesktop"; }
      { name = "brave-browser"; type = "InteractiveDesktop"; }
      { name = "firefox"; type = "InteractiveDesktop"; }
      { name = "firefox-bin"; type = "InteractiveDesktop"; }
      { name = "google-chrome"; type = "InteractiveDesktop"; }
      { name = "google-chrome-stable"; type = "InteractiveDesktop"; }
      { name = "chrome"; type = "InteractiveDesktop"; }
      { name = "code"; type = "InteractiveDesktop"; }
      { name = "code-oss"; type = "InteractiveDesktop"; }
      { name = "code-insiders"; type = "InteractiveDesktop"; }
      { name = "code.js"; type = "InteractiveDesktop"; }
      { name = "kiro"; type = "InteractiveDesktop"; }
      { name = ".kiro-wrapped"; type = "InteractiveDesktop"; }
      { name = "chrome_crashpad_handler"; type = "DesktopHelper"; }
      { name = "copilot-agent-linux"; type = "DesktopHelper"; }
      { name = "ollama"; type = "Heavy_CPU"; }
    ];
  };

  systemd.services.desktop-cache-warm = {
    description = "Warm page cache for launch-sensitive desktop apps";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = desktopCacheWarm;
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.desktop-cache-warm = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "desktop-cache-warm.service";
      OnBootSec = "20s";
      OnUnitInactiveSec = "2h";
      AccuracySec = "1m";
      RandomizedDelaySec = "3m";
    };
  };
}
