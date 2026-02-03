# Power Management Tools and Utilities
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "power-status" ''
      echo "⚡ System Power Management Status"
      echo "================================="
      
      # Battery information
      if command -v acpi >/dev/null 2>&1; then
        echo "🔋 Battery Status:"
        acpi -b
        echo ""
      fi
      
      # Power consumption
      if command -v powertop >/dev/null 2>&1; then
        echo "💡 Current Power Consumption:"
        timeout 3 powertop --dump --quiet 2>/dev/null | grep -E "The battery reports|Wh" | head -2 || echo "Run 'sudo powertop' for detailed analysis"
        echo ""
      fi
      
      # CPU governor and frequency
      echo "🏃 CPU Performance:"
      if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"
        echo "Current frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 'unknown') kHz"
        echo "Min frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo 'unknown') kHz"
        echo "Max frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo 'unknown') kHz"
      else
        echo "CPU frequency information not available"
      fi
      
      echo ""
      echo "🔧 Power Management Services:"
      systemctl is-active tlp 2>/dev/null && echo "✅ TLP: active" || echo "❌ TLP: inactive"
      systemctl is-active thermald 2>/dev/null && echo "✅ thermald: active" || echo "❌ thermald: inactive"
      
      echo ""
      echo "🚫 Conflicting Services (should be inactive):"
      systemctl is-active auto-cpufreq 2>/dev/null && echo "⚠️  auto-cpufreq: ACTIVE (CONFLICT!)" || echo "✅ auto-cpufreq: inactive"
      systemctl is-active power-profiles-daemon 2>/dev/null && echo "⚠️  power-profiles-daemon: ACTIVE (CONFLICT!)" || echo "✅ power-profiles-daemon: inactive"
      
      echo ""
      echo "📊 TLP Status:"
      if command -v tlp-stat >/dev/null 2>&1; then
        tlp-stat -s 2>/dev/null | head -10
      else
        echo "TLP not available or not running"
      fi
    '')
    
    (pkgs.writeShellScriptBin "power-optimize" ''
      echo "🔧 Optimizing power settings..."
      
      # Check if running on battery
      if acpi -a 2>/dev/null | grep -q "off-line"; then
        echo "📱 Running on battery - applying power saving settings"
        MODE="battery"
      else
        echo "🔌 Running on AC power - applying performance settings"
        MODE="ac"
      fi
      
      # Apply TLP settings
      if systemctl is-active tlp >/dev/null 2>&1; then
        echo "Restarting TLP service..."
        sudo systemctl restart tlp
        echo "✅ TLP restarted"
      else
        echo "❌ TLP service not running"
      fi
      
      # Set CPU governor based on power source
      if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        if [ "$MODE" = "battery" ]; then
          echo "Setting CPU governor to powersave..."
          echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
        else
          echo "Setting CPU governor to performance..."
          echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
        fi
        echo "✅ CPU governor updated"
      fi
      
      echo ""
      echo "🎯 Optimization complete! Run 'power-status' to check current settings."
    '')
    
    (pkgs.writeShellScriptBin "thermal-monitor" ''
      echo "🌡️  Real-time Thermal Monitoring"
      echo "Press Ctrl+C to stop"
      echo "================================="
      
      while true; do
        clear
        echo "🌡️  Thermal Status - $(date)"
        echo "================================="
        
        # CPU temperature
        if command -v sensors >/dev/null 2>&1; then
          echo "🔥 CPU Temperature:"
          sensors | grep -E "(Core|Package|Tctl)" | head -4
          echo ""
        fi
        
        # CPU frequency
        echo "⚡ CPU Frequency:"
        if [ -f /proc/cpuinfo ]; then
          grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{printf "  Core %d: %.0f MHz\n", NR-1, $4}'
        fi
        
        # Load average
        echo ""
        echo "📊 System Load:"
        echo "  $(uptime | awk -F'load average:' '{print $2}')"
        
        # System thermal zones
        echo ""
        echo "🌡️  Thermal Zones:"
        if [ -d /sys/class/thermal ]; then
          for zone in /sys/class/thermal/thermal_zone*; do
            if [ -f "$zone/type" ] && [ -f "$zone/temp" ]; then
              type=$(cat "$zone/type" 2>/dev/null || echo "unknown")
              temp=$(cat "$zone/temp" 2>/dev/null || echo "0")
              temp_c=$((temp / 1000))
              echo "  $type: ''${temp_c}°C"
            fi
          done
        fi
        
        sleep 2
      done
    '')
  ];
}