pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: StateService.get("caffeine", false)

    function toggleInhibit() {
        inhibit = !inhibit;
    }

    onInhibitChanged: {
        if (StateService.initialized) {
            StateService.set("caffeine", inhibit);
        }

        if (inhibit) {
            if (!systemdInhibitProc.running)
                systemdInhibitProc.running = true;
        } else if (systemdInhibitProc.running) {
            systemdInhibitProc.running = false;
        }
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.inhibit = StateService.get("caffeine", false);
        }
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
        }
    }

    Process {
        id: systemdInhibitProc
        running: root.inhibit
        command: [
            "systemd-inhibit",
            "--what=idle:sleep:handle-lid-switch",
            "--who=Vibeshell",
            "--why=Vibeshell caffeine mode is enabled",
            "--mode=block",
            "sleep",
            "infinity"
        ]

        onExited: exitCode => {
            if (root.inhibit) {
                console.warn("systemd-inhibit exited with code " + exitCode + ". Restarting caffeine inhibitor...");
                restartSystemdInhibitTimer.start();
            }
        }
    }

    Timer {
        id: restartSystemdInhibitTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.inhibit && !systemdInhibitProc.running)
                systemdInhibitProc.running = true;
        }
    }
}
