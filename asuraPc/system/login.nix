# Login Manager Configuration
{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --remember --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
      user = "greeter";
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
    ExecStartPre = [
      "-/run/current-system/sw/bin/rm -f /run/user/1000/wayland-0.lock"
      "-/run/current-system/sw/bin/rm -f /run/user/1000/wayland-1.lock"
    ];
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
