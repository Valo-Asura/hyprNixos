# Hypridle is a daemon that listens for user activity and runs commands when the user is idle.
{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {

      general = {
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
        lock_cmd = "/run/current-system/sw/bin/noctalia-safe-lock";
        before_sleep_cmd = "/run/current-system/sw/bin/noctalia-safe-lock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "/run/current-system/sw/bin/noctalia-safe-lock";
        }

        {
          timeout = 660;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
