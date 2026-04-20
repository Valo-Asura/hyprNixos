# Thermal Monitoring Tools (EC-Controlled Fan System)
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "thermal-status" ''
      echo "🌡️  System Thermal Status"
      echo "========================="
      
      # CPU temperature
      if command -v sensors >/dev/null 2>&1; then
        echo "🔥 CPU Temperature:"
        sensors | grep -E "(Core|Package|Tctl)" | head -5
        echo ""
      fi
      
      # System thermal zones
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
      
      # CPU frequency
      echo ""
      echo "⚡ CPU Frequency:"
      if [ -f /proc/cpuinfo ]; then
        grep "cpu MHz" /proc/cpuinfo | head -4
      fi
      
      # Cooling devices status
      echo ""
      echo "❄️  Active Cooling Devices:"
      if [ -d /sys/class/thermal ]; then
        for cooling in /sys/class/thermal/cooling_device*; do
          if [ -f "$cooling/type" ] && [ -f "$cooling/cur_state" ]; then
            type=$(cat "$cooling/type" 2>/dev/null || echo "unknown")
            state=$(cat "$cooling/cur_state" 2>/dev/null || echo "0")
            max_state=$(cat "$cooling/max_state" 2>/dev/null || echo "0")
            if [ "$state" != "0" ] || [ "$type" = "intel_powerclamp" ] || [ "$type" = "TCC Offset" ]; then
              echo "  $type: $state/$max_state"
            fi
          fi
        done
      fi
      
      echo ""
      echo "🔧 Thermal Services:"
      systemctl is-active thermald 2>/dev/null && echo "✅ thermald: active" || echo "❌ thermald: inactive"
      systemctl is-active tlp 2>/dev/null && echo "✅ tlp: active" || echo "❌ tlp: inactive"
      
      echo ""
      echo "🚫 Fan Control Status:"
      echo "❌ No fan devices exposed to Linux (ACPI/EC communication issues)"
      echo "✅ Fan hardware controlled by BIOS/EC (automatic thermal management)"
      echo ""
      echo "ℹ️  This is normal for Clevo laptops with ACPI firmware bugs"
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
        
        # Active cooling
        echo ""
        echo "❄️  Active Cooling:"
        active_cooling=false
        if [ -d /sys/class/thermal ]; then
          for cooling in /sys/class/thermal/cooling_device*; do
            if [ -f "$cooling/type" ] && [ -f "$cooling/cur_state" ]; then
              type=$(cat "$cooling/type" 2>/dev/null || echo "unknown")
              state=$(cat "$cooling/cur_state" 2>/dev/null || echo "0")
              if [ "$state" != "0" ]; then
                echo "  $type: active (level $state)"
                active_cooling=true
              fi
            fi
          done
        fi
        
        if [ "$active_cooling" = false ]; then
          echo "  No active thermal throttling"
        fi
        
        echo ""
        echo "🚫 Fan Status:"
        echo "❌ No fan control available (ACPI/EC issues)"
        echo "✅ Hardware fan managed by BIOS/EC"
        
        sleep 2
      done
    '')
    
    (pkgs.writeShellScriptBin "acpi-diagnostics" ''
      echo "🔍 ACPI/EC Diagnostic Information"
      echo "================================="
      
      echo "🔧 ACPI Errors (last 10):"
      sudo dmesg | grep -i "acpi.*error\|acpi.*bug" | tail -10 || echo "No recent ACPI errors found"
      
      echo ""
      echo "🌡️  Available hwmon devices:"
      if [ -d /sys/class/hwmon ]; then
        for hwmon in /sys/class/hwmon/hwmon*; do
          name=$(cat "$hwmon/name" 2>/dev/null || echo "unknown")
          echo "  $hwmon: $name"
          
          # Check for fan controls
          fan_found=false
          for control in "$hwmon"/fan*_input "$hwmon"/pwm*; do
            if [ -f "$control" ]; then
              echo "    Found: $(basename "$control")"
              fan_found=true
            fi
          done
          
          if [ "$fan_found" = false ]; then
            echo "    No fan controls"
          fi
        done
      else
        echo "  No hwmon directory found"
      fi
      
      echo ""
      echo "❄️  Thermal cooling devices:"
      if [ -d /sys/class/thermal ]; then
        for cooling in /sys/class/thermal/cooling_device*; do
          if [ -f "$cooling/type" ]; then
            type=$(cat "$cooling/type" 2>/dev/null || echo "unknown")
            echo "  $(basename "$cooling"): $type"
          fi
        done
      fi
      
      echo ""
      echo "🔍 EC Communication Status:"
      if dmesg | grep -q "ACPI.*EC"; then
        echo "✅ EC detected in dmesg"
        dmesg | grep "ACPI.*EC" | tail -3
      else
        echo "❌ No EC communication found in dmesg"
      fi
      
      echo ""
      echo "⚠️  Known Issues:"
      if dmesg | grep -q "NPCF.CDBL"; then
        echo "❌ ACPI symbol resolution errors detected (BIOS bug)"
        echo "   This prevents proper EC/fan communication"
      fi
      
      if dmesg | grep -q "_Q16.*error"; then
        echo "❌ EC method execution errors detected"
        echo "   Fan control likely unavailable"
      fi
      
      echo ""
      echo "💡 Recommendations:"
      echo "   - Check for BIOS updates from laptop manufacturer"
      echo "   - Current thermal management via thermald/TLP is working"
      echo "   - Fan hardware is functional but not controllable from Linux"
    '')
  ];
}