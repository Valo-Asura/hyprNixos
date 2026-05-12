# Custom microfetch configuration
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "microfetch-custom" ''
      # Custom microfetch with enhanced information

      # Colors
      RESET="\033[0m"
      BOLD="\033[1m"
      CYAN="\033[36m"
      GREEN="\033[32m"
      YELLOW="\033[33m"
      BLUE="\033[34m"
      MAGENTA="\033[35m"
      RED="\033[31m"

      # System info
      USER=$(whoami)
      HOSTNAME=$(hostname)
      DISTRO="NixOS $(nixos-version | cut -d' ' -f1-2)"
      KERNEL=$(uname -r)
      UPTIME=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//')
      SHELL=$(basename "$SHELL")

      # Hardware info
      CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//' | sed 's/ \+/ /g')
      MEMORY=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')

      # Temperature (if available)
      if command -v sensors >/dev/null 2>&1; then
        TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}' | sed 's/+//' | sed 's/°C.*/°C/')
        if [ -z "$TEMP" ]; then
          TEMP=$(sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C.*/°C/')
        fi
      fi

      # Battery (if available)
      if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)%
        BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)
      fi

      # Git info (if in a git repo)
      if git rev-parse --git-dir >/dev/null 2>&1; then
        GIT_BRANCH=$(git branch --show-current 2>/dev/null)
        GIT_STATUS=$(git status --porcelain 2>/dev/null | wc -l)
      fi

      # Display
      echo -e "   ''${CYAN}╭─────────────────────────────────────╮''${RESET}"
      echo -e "   ''${CYAN}│''${RESET} ''${BOLD}''${GREEN}$USER''${RESET}''${BOLD}@''${BLUE}$HOSTNAME''${RESET} ''${CYAN}│''${RESET}"
      echo -e "   ''${CYAN}├─────────────────────────────────────┤''${RESET}"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}OS''${RESET}     $DISTRO"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Kernel''${RESET} $KERNEL"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Uptime''${RESET} $UPTIME"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Shell''${RESET}  $SHELL"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}CPU''${RESET}    $CPU"
      echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Memory''${RESET} $MEMORY"

      if [ -n "$TEMP" ]; then
        echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Temp''${RESET}   $TEMP"
      fi

      if [ -n "$BATTERY" ]; then
        if [ "$BAT_STATUS" = "Charging" ]; then
          echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Battery''${RESET} $BATTERY ''${GREEN}(Charging)''${RESET}"
        elif [ "$BAT_STATUS" = "Discharging" ]; then
          echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Battery''${RESET} $BATTERY ''${RED}(Discharging)''${RESET}"
        else
          echo -e "   ''${CYAN}│''${RESET} ''${YELLOW}Battery''${RESET} $BATTERY ''${GREEN}(Full)''${RESET}"
        fi
      fi

      if [ -n "$GIT_BRANCH" ]; then
        echo -e "   ''${CYAN}├─────────────────────────────────────┤''${RESET}"
        if [ "$GIT_STATUS" -gt 0 ]; then
          echo -e "   ''${CYAN}│''${RESET} ''${MAGENTA}Git''${RESET}    $GIT_BRANCH ''${RED}($GIT_STATUS changes)''${RESET}"
        else
          echo -e "   ''${CYAN}│''${RESET} ''${MAGENTA}Git''${RESET}    $GIT_BRANCH ''${GREEN}(clean)''${RESET}"
        fi
      fi

      echo -e "   ''${CYAN}╰─────────────────────────────────────╯''${RESET}"
    '')
  ];

  # Create alias for the custom microfetch
  programs.fish.shellAliases.mf = "microfetch-custom";
}
