import QtQuick
import qs.modules.components
import qs.modules.services
import qs.modules.theme
import Quickshell.Io

ActionGrid {
    id: root

    signal itemSelected

    layout: "grid"
    columns: 6
    buttonSize: 62
    iconSize: 22
    spacing: 6
    textSpacing: 0
    hoverTextOnly: true

    Process {
        id: actionProcess
        running: false
    }

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    actions: [
        {
            icon: Icons.lock,
            text: "Lock",
            tooltip: "Lock Session",
            command: "/run/current-system/sw/bin/ambxst-safe-lock"
        },
        {
            icon: Icons.suspend,
            text: "Sleep",
            tooltip: "Suspend",
            command: "/run/current-system/sw/bin/systemctl suspend"
        },
        {
            icon: Icons.logout,
            text: "Exit",
            tooltip: "Exit Hyprland",
            command: "/run/current-system/sw/bin/hyprctl dispatch exit"
        },
        {
            icon: Icons.reboot,
            text: "Reboot",
            tooltip: "Reboot",
            command: "/run/current-system/sw/bin/systemctl reboot"
        },
        {
            icon: Icons.firmware,
            text: "UEFI",
            tooltip: "Reboot to UEFI Firmware",
            command: "/run/current-system/sw/bin/systemctl reboot --firmware-setup"
        },
        {
            icon: Icons.shutdown,
            text: "Off",
            tooltip: "Power Off",
            command: "/run/current-system/sw/bin/systemctl poweroff"
        }
    ]

    onActionTriggered: action => {
        console.log("Action triggered:", action.command);
        if (action.command) {
            actionProcess.command = ["/run/current-system/sw/bin/bash", "-c", action.command];
            console.log("Starting process with command:", actionProcess.command);
            actionProcess.running = true;
        }
        root.itemSelected();
    }
}
