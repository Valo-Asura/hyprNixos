import QtQuick
import qs.modules.components
import qs.modules.theme
import Quickshell

ToggleButton {
    id: wallpaperButton
    buttonIcon: Icons.wallpapers
    tooltipText: "Wallpaper Manager (skwd)"
    onToggle: function () {
        Quickshell.execDetached(["skwd", "wall", "toggle"]);
    }
}
