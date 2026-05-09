import QtQuick
import qs.modules.components
import qs.modules.services
import qs.modules.theme
import Quickshell.Io

ActionGrid {
    id: root

    signal itemSelected

    layout: "row"
    buttonSize: 48
    iconSize: 20
    spacing: 8

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
            tooltip: "Lock Session",
            command: "/run/current-system/sw/bin/hyprlock"
        },
        {
            icon: Icons.suspend,
            tooltip: "Suspend",
            command: "/run/current-system/sw/bin/systemctl suspend"
        },
        {
            icon: Icons.logout,
            tooltip: "Exit Hyprland",
            command: "/run/current-system/sw/bin/hyprctl dispatch exit"
        },
        {
            icon: Icons.reboot,
            tooltip: "Reboot",
            command: "/run/current-system/sw/bin/systemctl reboot"
        },
        {
            icon: Icons.firmware,
            tooltip: "UEFI Firmware",
            command: "/run/current-system/sw/bin/systemctl reboot --firmware-setup"
        },
        {
            icon: Icons.shutdown,
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
