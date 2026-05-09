# Waybar — declarative config (files sourced from ./config and ./style.css)
{ config, pkgs, ... }:

let
  ambxstWeather = ../ambxst/scripts/weather.sh;
  weatherScript = pkgs.writeShellScript "waybar-weather" ''
    set -euo pipefail

    jq_bin="${pkgs.jq}/bin/jq"
    awk_bin="${pkgs.gawk}/bin/awk"
    config_file="''${XDG_CONFIG_HOME:-$HOME/.config}/Ambxst/config/weather.json"

    location=""
    unit="C"
    if [ -r "$config_file" ]; then
      location="$("$jq_bin" -r '.location // ""' "$config_file" 2>/dev/null || true)"
      unit="$("$jq_bin" -r '.unit // "C"' "$config_file" 2>/dev/null || echo C)"
    fi

    raw="$("${ambxstWeather}" "$location" 2>/dev/null || true)"
    if ! printf '%s' "$raw" | "$jq_bin" -e '.current or .current_weather' >/dev/null 2>&1; then
      "$jq_bin" -cn \
        --arg text "Weather unavailable" \
        --arg tooltip "Weather request failed" \
        '{text: $text, tooltip: $tooltip, class: "warning"}'
      exit 0
    fi

    code="$(printf '%s' "$raw" | "$jq_bin" -r '(.current.weather_code // .current_weather.weathercode // 0)')"
    temp_c="$(printf '%s' "$raw" | "$jq_bin" -r '(.current.temperature_2m // .current_weather.temperature // 0)')"
    high_c="$(printf '%s' "$raw" | "$jq_bin" -r '(.daily.temperature_2m_max[0] // empty)')"
    low_c="$(printf '%s' "$raw" | "$jq_bin" -r '(.daily.temperature_2m_min[0] // empty)')"
    resolved_location="$(printf '%s' "$raw" | "$jq_bin" -r '(.ambxst.location // empty)')"

    if [ -z "$resolved_location" ]; then
      resolved_location="$location"
    fi
    if [ -z "$resolved_location" ]; then
      resolved_location="Current location"
    fi

    if [ "$unit" = "F" ]; then
      temp="$("$awk_bin" -v t="$temp_c" 'BEGIN { printf "%.0f", (t * 9 / 5) + 32 }')"
      if [ -n "$high_c" ]; then
        high="$("$awk_bin" -v t="$high_c" 'BEGIN { printf "%.0f", (t * 9 / 5) + 32 }')"
      else
        high=""
      fi
      if [ -n "$low_c" ]; then
        low="$("$awk_bin" -v t="$low_c" 'BEGIN { printf "%.0f", (t * 9 / 5) + 32 }')"
      else
        low=""
      fi
    else
      temp="$("$awk_bin" -v t="$temp_c" 'BEGIN { printf "%.0f", t }')"
      high="$("$awk_bin" -v t="''${high_c:-0}" 'BEGIN { printf "%.0f", t }')"
      low="$("$awk_bin" -v t="''${low_c:-0}" 'BEGIN { printf "%.0f", t }')"
    fi

    symbol="?"
    description="Unknown"
    case "$code" in
      0) symbol="☀"; description="Clear sky" ;;
      1) symbol="󰖙"; description="Mainly clear" ;;
      2) symbol="󰖕"; description="Partly cloudy" ;;
      3) symbol="☁"; description="Overcast" ;;
      45|48) symbol="󰖑"; description="Fog" ;;
      51|53|55|56|57) symbol="󰖗"; description="Drizzle" ;;
      61|63|65|66|67|80|81|82) symbol="󰖖"; description="Rain" ;;
      71|73|75|77|85|86) symbol="󰼶"; description="Snow" ;;
      95|96|99) symbol="󰙾"; description="Thunderstorm" ;;
    esac

    short_location="''${resolved_location%%,*}"
    text="$symbol $temp°$unit $short_location"
    tooltip="$resolved_location"$'\n'"$description"
    if [ -n "''${high:-}" ] && [ -n "''${low:-}" ]; then
      tooltip="$tooltip"$'\n'"High: $high°$unit  Low: $low°$unit"
    fi

    "$jq_bin" -cn \
      --arg text "$text" \
      --arg tooltip "$tooltip" \
      '{text: $text, tooltip: $tooltip}'
  '';
in
{
  programs.waybar.enable = true;

  home.packages = with pkgs; [
    papirus-icon-theme # tray icons + consistent icon theme
  ];

  xdg.configFile."waybar/config".source = ./config;
  xdg.configFile."waybar/style.css".source = ./style.css;
  xdg.configFile."hypr/scripts/weather.sh".source = weatherScript;
}
