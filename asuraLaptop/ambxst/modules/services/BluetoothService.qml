pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool discovering: false
    property bool connected: false
    property int connectedDevices: 0
    
    readonly property list<BluetoothDevice> devices: []
    
    // Cached sorted device list - only updates when devices change
    property list<var> friendlyDeviceList: []
    
    // Queue for batching updateInfo calls
    property var pendingInfoUpdates: []
    property bool isProcessingInfoQueue: false

    function updateFriendlyList() {
        friendlyDeviceList = [...devices].sort((a, b) => {
            // Connected devices first
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            // Then paired devices
            if (a.paired && !b.paired) return -1;
            if (!a.paired && b.paired) return 1;
            // Then by name
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    // Batch process info updates with delay between each
    function queueInfoUpdate(device: BluetoothDevice) {
        if (pendingInfoUpdates.indexOf(device) === -1) {
            pendingInfoUpdates.push(device);
        }
        if (!isProcessingInfoQueue) {
            processNextInfoUpdate();
        }
    }

    function processNextInfoUpdate() {
        if (pendingInfoUpdates.length === 0) {
            isProcessingInfoQueue = false;
            updateFriendlyList();
            return;
        }
        
        isProcessingInfoQueue = true;
        const device = pendingInfoUpdates.shift();
        if (device) {
            device.updateInfo();
        }
        // Process next after a small delay
        infoQueueTimer.restart();
    }

    Timer {
        id: infoQueueTimer
        interval: 50  // 50ms between each info request
        running: false
        repeat: false
        onTriggered: root.processNextInfoUpdate()
    }

    // Control functions
    function toggle() {
        setEnabled(!enabled);
    }

    function setEnabled(value: bool) {
        toggleProcess.command = ["bluetoothctl", "power", value ? "on" : "off"];
        toggleProcess.running = true;
    }

    function startDiscovery() {
        if (enabled) {
            discovering = true;
            scanProcess.command = ["bluetoothctl", "scan", "on"];
            scanProcess.running = true;
            // Stop scanning after 15 seconds
            scanTimer.restart();
        }
    }

    function stopDiscovery() {
        discovering = false;
        stopScanProcess.command = ["bluetoothctl", "scan", "off"];
        stopScanProcess.running = true;
        scanTimer.stop();
    }

    function connectDevice(address: string) {
        connectProcess.command = ["bluetoothctl", "connect", address];
        connectProcess.running = true;
    }

    function disconnectDevice(address: string) {
        disconnectProcess.command = ["bluetoothctl", "disconnect", address];
        disconnectProcess.running = true;
    }

    function pairDevice(address: string) {
        pairProcess.command = ["bluetoothctl", "pair", address];
        pairProcess.running = true;
    }

    function trustDevice(address: string) {
        trustProcess.command = ["bluetoothctl", "trust", address];
        trustProcess.running = true;
    }

    function removeDevice(address: string) {
        removeProcess.command = ["bluetoothctl", "remove", address];
        removeProcess.running = true;
    }

    function updateStatus() {
        checkPowerProcess.running = true;
    }

    // Timers
    Timer {
        id: updateTimer
        interval: 5000
        running: root.enabled
        repeat: true
        onTriggered: root.updateDevices()
    }

    Timer {
        id: scanTimer
        interval: 15000
        running: false
        repeat: false
        onTriggered: root.stopDiscovery()
    }

    // Processes
    Process {
        id: toggleProcess
        running: false
        onExited: {
            root.updateStatus();
            if (root.enabled) {
                root.updateDevices();
            }
        }
    }

    Process {
        id: scanProcess
        running: false
        onExited: root.updateDevices()
    }

    Process {
        id: stopScanProcess
        running: false
    }

    Process {
        id: connectProcess
        running: false
        onExited: root.updateDevices()
    }

    Process {
        id: disconnectProcess
        running: false
        onExited: root.updateDevices()
    }

    Process {
        id: pairProcess
        running: false
        onExited: root.updateDevices()
    }

    Process {
        id: trustProcess
        running: false
    }

    Process {
        id: removeProcess
        running: false
        onExited: root.updateDevices()
    }

    Process {
        id: checkPowerProcess
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "";
                root.enabled = output === "yes";
                
                if (root.enabled) {
                    checkConnectedProcess.running = true;
                } else {
                    root.connected = false;
                    root.connectedDevices = 0;
                    root.discovering = false;
                }
            }
        }
    }

    Process {
        id: checkConnectedProcess
        command: ["bash", "-c", "bluetoothctl devices Connected | wc -l"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "0";
                root.connectedDevices = parseInt(output) || 0;
                root.connected = root.connectedDevices > 0;
            }
        }
    }

    function updateDevices() {
        getDevicesProcess.running = true;
    }

    Process {
        id: getDevicesProcess
        command: ["bash", "-c", "bluetoothctl devices"]
        running: false
        property string buffer: ""
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => {
                getDevicesProcess.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = getDevicesProcess.buffer;
            getDevicesProcess.buffer = "";
            
            const deviceLines = text.trim().split("\n").filter(l => l.startsWith("Device "));
            const deviceAddresses = deviceLines.map(line => {
                const parts = line.split(" ");
                return {
                    address: parts[1] || "",
                    name: parts.slice(2).join(" ") || "Unknown"
                };
            }).filter(d => d.address);

            // Update existing devices and add new ones
            const rDevices = root.devices;
            
            // Remove devices that no longer exist
            const toRemove = rDevices.filter(rd => !deviceAddresses.find(d => d.address === rd.address));
            for (const device of toRemove) {
                const idx = rDevices.indexOf(device);
                if (idx >= 0) {
                    rDevices.splice(idx, 1);
                    device.destroy();
                }
            }
            
            // Add or update devices
            for (const deviceData of deviceAddresses) {
                const existing = rDevices.find(d => d.address === deviceData.address);
                if (existing) {
                    existing.name = deviceData.name;
                    root.queueInfoUpdate(existing);
                } else {
                    const newDevice = deviceComp.createObject(root, {
                        address: deviceData.address,
                        name: deviceData.name
                    });
                    rDevices.push(newDevice);
                    root.queueInfoUpdate(newDevice);
                }
            }
            
            // If no devices to update, just refresh the list
            if (deviceAddresses.length === 0) {
                root.updateFriendlyList();
            }
        }
    }

    Component {
        id: deviceComp
        BluetoothDevice {}
    }

    Component.onCompleted: {
        updateStatus();
    }
}
