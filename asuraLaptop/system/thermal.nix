# Thermal Management and Fan Control
{ pkgs, lib, ... }:

{
  # Enable thermal management
  services.thermald.enable = true;
  
  # Explicitly disable conflicting power management services
  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = lib.mkForce false;
  
  # Enable TLP for power and thermal management
  services.tlp = {
    enable = true;
    settings = {
      # CPU scaling governor
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # CPU energy performance preference
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # CPU min/max frequencies
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;
      
      # Platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      
      # Thermal thresholds (battery charge limits)
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      # Additional power optimization
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";  # Disabled: WiFi power saving causes dropouts/lag
      
      # USB autosuspend
      USB_AUTOSUSPEND = 1;
      USB_BLACKLIST_PHONE = 1;
    };
  };
  
  # Add thermal monitoring tools
  environment.systemPackages = with pkgs; [
    lm_sensors     # Hardware monitoring (sensors command)
    acpi           # ACPI information
    powertop       # Power consumption analysis
  ];
  
  # Enable ACPI for better hardware control
  boot.kernelModules = [ 
    "acpi_cpufreq" 
    "coretemp" 
    # Note: Fan controller modules removed - no controllable fans on this hardware
    # "nct6775" and "it87" don't work due to ACPI/EC communication issues
  ];
  
  # Kernel parameters for better thermal management
  boot.kernelParams = [
    "acpi_enforce_resources=lax"  # Allow access to more ACPI resources
    # Note: acpi_osi=Linux removed - can cause issues on some Clevo laptops
  ];
  
  # Enable hardware monitoring (remove hddtemp as it's deprecated)
  # hardware.sensor.hddtemp.enable = true;
  
  # Note: This laptop uses EC-controlled fans with no Linux interface
  # Fan control is handled automatically by BIOS/EC based on thermal conditions
}