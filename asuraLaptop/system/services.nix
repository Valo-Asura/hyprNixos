# System Services Configuration
{ pkgs, ... }:

let
  configFile = "/etc/fan-boost/config";
  fanBoostScript = pkgs.writeShellScript "fan-boost-auto" ''
    set -euo pipefail

    if [ ! -r "${configFile}" ]; then
      exit 0
    fi

    # shellcheck disable=SC1091
    . "${configFile}"

    keycode="''${KEYCODE:-}"
    if [ -z "$keycode" ] || [ "$keycode" -le 0 ]; then
      exit 0
    fi

    CPU_HIGH="''${CPU_HIGH:-75}"
    CPU_LOW="''${CPU_LOW:-65}"
    GPU_HIGH="''${GPU_HIGH:-70}"
    GPU_LOW="''${GPU_LOW:-60}"

    get_hwmon_max_temp() {
      local match="$1"
      local max=0
      local hwmon name
      for hwmon in /sys/class/hwmon/hwmon*; do
        [ -r "$hwmon/name" ] || continue
        name="$(cat "$hwmon/name")"
        if [ "$name" = "$match" ]; then
          for t in "$hwmon"/temp*_input; do
            [ -r "$t" ] || continue
            val="$(cat "$t")"
            val=$((val / 1000))
            if [ "$val" -gt "$max" ]; then
              max="$val"
            fi
          done
        fi
      done
      echo "$max"
    }

    cpu_temp="$(get_hwmon_max_temp coretemp)"
    gpu_temp="$(get_hwmon_max_temp nvidia)"
    if [ "$gpu_temp" -le 0 ]; then
      gpu_temp="$(get_hwmon_max_temp amdgpu)"
    fi

    state_dir="/var/lib/fan-boost"
    state_file="$state_dir/state"
    mkdir -p "$state_dir"
    prev="$(cat "$state_file" 2>/dev/null || echo 0)"

    boost=0
    if [ "$cpu_temp" -ge "$CPU_HIGH" ] || [ "$gpu_temp" -ge "$GPU_HIGH" ]; then
      boost=1
    fi

    if [ "$boost" -eq 1 ] && [ "$prev" -ne 1 ]; then
      ${pkgs.ydotool}/bin/ydotool key "$keycode:1" "$keycode:0"
      echo 1 > "$state_file"
    elif [ "$boost" -eq 0 ] && [ "$prev" -eq 1 ]; then
      if [ "$cpu_temp" -le "$CPU_LOW" ] && [ "$gpu_temp" -le "$GPU_LOW" ]; then
        ${pkgs.ydotool}/bin/ydotool key "$keycode:1" "$keycode:0"
        echo 0 > "$state_file"
      fi
    fi
  '';
in {
  services = {
    blueman.enable = true;
    dbus.enable = true;
    fwupd.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    upower.enable = true;
    printing.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  security.wrappers."gpu-screen-recorder" = {
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
    owner = "root";
    group = "root";
    setuid = true;
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

  # Auto fan boost on AC (Fn+1 via ydotool)
  programs.ydotool.enable = true;
  environment.systemPackages = with pkgs; [ wev ];

  environment.etc."fan-boost/config".text = ''
# Fan boost automation
# Keycode for Fn+1 fan boost toggle (use `wev` to detect)
KEYCODE=0

# Temperature thresholds in °C
CPU_HIGH=75
CPU_LOW=65
GPU_HIGH=70
GPU_LOW=60
'';

  systemd.services.fan-boost-auto = {
    description = "Auto fan boost on AC (Fn+1)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${fanBoostScript}";
    };
  };

  systemd.timers.fan-boost-auto = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20s";
      OnUnitActiveSec = "15s";
      Unit = "fan-boost-auto.service";
    };
  };
}
