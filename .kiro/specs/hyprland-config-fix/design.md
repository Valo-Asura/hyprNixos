# Design Document

## Overview

This design implements the addition of ambxst to the Hyprland startup sequence. The solution involves extending the exec-once list in the existing Hyprland Nix configuration while preserving all current settings.

## Architecture

The implementation involves modifying the existing Hyprland Nix configuration file (`asuraLaptop/hyprland/default.nix`) to:

1. Add ambxst to the exec-once startup commands
2. Maintain all existing configuration settings unchanged
3. Preserve the current gesture configuration as-is

## Components and Interfaces

### Configuration Components

**Startup Command Addition:**
- Extend the existing `exec-once` array to include ambxst
- Maintain execution order to ensure proper service initialization
- Preserve all existing configuration settings

### File Structure
```
asuraLaptop/hyprland/
├── default.nix (primary modification target)
├── animations.nix (unchanged)
├── bindings.nix (unchanged)
├── polkitagent.nix (unchanged)
└── hypridle.nix (unchanged)
```

## Data Models

### Exec-Once Configuration Schema
```nix
exec-once = [
  # Existing commands (preserved)
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
  "systemctl --user start hyprpolkitagent"
  "code"
  "swww init"
  "swww img /home/asura/.config/background/126270092_p0.jpg"
  # New addition
  "ambxst"
];
```

## Error Handling

### Configuration Validation
- The Nix configuration will be validated during the home-manager rebuild process
- Invalid gesture options will be caught at build time rather than runtime
- Hyprland will validate the configuration on startup and report any remaining issues

### Service Startup Handling
- ambxst will be added to exec-once, which handles service startup failures gracefully
- If ambxst is not available on the system, Hyprland will log the error but continue startup
- No additional error handling is required as exec-once is non-blocking

## Testing Strategy

### Configuration Testing
1. **Build Validation**: Verify the Nix configuration builds successfully with `home-manager build`
2. **Service Startup**: Confirm ambxst starts during Hyprland initialization
3. **Existing Functionality**: Ensure all current Hyprland features remain unchanged

### Regression Testing
1. **Existing Functionality**: Ensure all current Hyprland features remain functional
2. **Performance**: Verify no performance degradation from configuration changes
3. **Compatibility**: Test with different Hyprland versions if applicable

## Implementation Notes

### Startup Sequence Considerations
- ambxst is added after system services but before user applications
- Position in exec-once array ensures proper initialization order
- No dependencies on other startup commands, making it safe to add
- All existing configuration remains unchanged