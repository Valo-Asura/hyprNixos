import qs.modules.components
import qs.modules.globals
import qs.modules.theme

ToggleButton {
    id: settingsButton
    buttonIcon: Icons.gear
    tooltipText: "Vibeshell settings"
    onToggle: function () {
        GlobalStates.openSettings();
    }
}
