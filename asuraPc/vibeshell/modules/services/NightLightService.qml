pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: StateService.get("nightLight", false)
    property real intensity: StateService.get("nightLightIntensity", 0.5)
    property bool restartPending: false
    readonly property int coolestTemperature: 6500
    readonly property int warmestTemperature: 2500
    readonly property int temperature: Math.round(coolestTemperature - (Math.max(0, Math.min(1, intensity)) * (coolestTemperature - warmestTemperature)))
    
    property Process hyprsunsetProcess: Process {
        command: ["hyprsunset", "-t", root.temperature.toString()]
        running: false
        onStarted: {
            root.active = true
        }
        onExited: code => {
            if (!root.restartPending) {
                root.active = false
            }
        }
    }
    
    property Process killProcess: Process {
        command: ["pkill", "hyprsunset"]
        running: false
        onExited: code => {
            if (root.restartPending) {
                restartStartTimer.restart();
            } else {
                root.active = false
            }
        }
    }
    
    property Process checkRunningProcess: Process {
        command: ["pgrep", "hyprsunset"]
        running: false
        onExited: code => {
            const isRunning = code === 0
            
            // If state says active but not running, start it
            if (root.active && !isRunning) {
                console.log("NightLightService: Starting hyprsunset (state was active but not running)")
                hyprsunsetProcess.running = true
            } 
            // If state says inactive but running, kill it
            else if (!root.active && isRunning) {
                console.log("NightLightService: Stopping hyprsunset (state was inactive but running)")
                killProcess.running = true
            }
        }
    }

    function toggle() {
        if (active) {
            killProcess.running = true
        } else {
            hyprsunsetProcess.running = true
        }
    }

    function setIntensity(value) {
        const clamped = Math.max(0, Math.min(1, value));
        if (Math.abs(clamped - intensity) < 0.001) {
            return;
        }

        intensity = clamped;
        if (active) {
            restartTimer.restart();
        }
    }
    
    function syncState() {
        checkRunningProcess.running = true
    }

    onActiveChanged: {
        if (StateService.initialized) {
            StateService.set("nightLight", active);
        }
    }

    onIntensityChanged: {
        if (StateService.initialized) {
            StateService.set("nightLightIntensity", intensity);
        }
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.active = StateService.get("nightLight", false);
            root.intensity = StateService.get("nightLightIntensity", 0.5);
            root.syncState();
        }
    }

    // Auto-initialize on creation
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (StateService.initialized) {
                root.active = StateService.get("nightLight", false);
                root.intensity = StateService.get("nightLightIntensity", 0.5);
                root.syncState();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.active) {
                return;
            }

            root.restartPending = true;
            root.killProcess.running = true;
        }
    }

    Timer {
        id: restartStartTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (root.restartPending) {
                root.hyprsunsetProcess.command = ["hyprsunset", "-t", root.temperature.toString()];
                root.hyprsunsetProcess.running = true;
                root.restartPending = false;
            }
        }
    }
}
