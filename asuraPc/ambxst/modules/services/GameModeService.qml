pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool toggled: false
    property bool initialized: false
    
    property string stateFile: Quickshell.statePath("states.json")

    function writeStates(states) {
        writeStateProcess.command = ["python3", "-c",
            "import os, sys, tempfile\n" +
            "path = sys.argv[1]\n" +
            "data = sys.argv[2]\n" +
            "directory = os.path.dirname(path)\n" +
            "os.makedirs(directory, exist_ok=True)\n" +
            "fd, tmp = tempfile.mkstemp(prefix='.states.', dir=directory, text=True)\n" +
            "try:\n" +
            "    with os.fdopen(fd, 'w') as f:\n" +
            "        f.write(data)\n" +
            "        f.flush()\n" +
            "        os.fsync(f.fileno())\n" +
            "    os.replace(tmp, path)\n" +
            "except Exception:\n" +
            "    try:\n" +
            "        os.unlink(tmp)\n" +
            "    except FileNotFoundError:\n" +
            "        pass\n" +
            "    raise\n",
            root.stateFile,
            JSON.stringify(states)
        ]
        writeStateProcess.running = true
    }

    property Process enableProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            if (code === 0) {
                root.toggled = true
                root.saveState()
            }
        }
    }

    property Process disableProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            if (code === 0) {
                root.toggled = false
                root.saveState()
            }
        }
    }
    
    property Process writeStateProcess: Process {
        running: false
        stdout: SplitParser {}
    }
    
    property Process readCurrentStateProcess: Process {
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const content = text ? text.trim() : ""
                    let states = {}
                    if (content) {
                        states = JSON.parse(content)
                    }
                    // Update only our state
                    states.gameMode = root.toggled
                    
                    // Write back
                    root.writeStates(states)
                } catch (e) {
                    console.warn("GameModeService: Failed to update state:", e)
                }
            }
        }
        onExited: (code) => {
            // If file doesn't exist, create new with our state
            if (code !== 0) {
                const states = { gameMode: root.toggled }
                root.writeStates(states)
            }
        }
    }
    
    property Process readStateProcess: Process {
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const content = text ? text.trim() : ""
                    if (content) {
                        const states = JSON.parse(content)
                        if (states.gameMode !== undefined) {
                            root.toggled = states.gameMode
                            
                            // If state says it should be enabled, apply it
                            if (root.toggled) {
                                enableProcess.command = ["hyprctl", "--batch", 
                                    "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0"]
                                enableProcess.running = true
                            }
                        }
                    }
                } catch (e) {
                    console.warn("GameModeService: Failed to parse states:", e)
                }
                root.initialized = true
            }
        }
        onExited: (code) => {
            // If file doesn't exist, just mark as initialized
            if (code !== 0) {
                root.initialized = true
            }
        }
    }

    function toggle() {
        if (toggled) {
            disableProcess.command = ["hyprctl", "reload"]
            disableProcess.running = true
        } else {
            enableProcess.command = ["hyprctl", "--batch", 
                "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0"]
            enableProcess.running = true
        }
    }

    function saveState() {
        readCurrentStateProcess.command = ["cat", stateFile]
        readCurrentStateProcess.running = true
    }

    function loadState() {
        readStateProcess.command = ["cat", stateFile]
        readStateProcess.running = true
    }

    // Auto-initialize on creation
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (!root.initialized) {
                root.loadState()
            }
        }
    }
}
