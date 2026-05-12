# Hypridle is a daemon that listens for user activity and runs commands when the user is idle.
{ ... }: {
  services.hypridle = {
    enable = true;
    settings = {

      general = {
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
        lock_cmd = "vibeshell-safe-lock";
        before_sleep_cmd = "vibeshell-lock-before-sleep";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "vibeshell-safe-lock";
        }

        {
          timeout = 660;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
