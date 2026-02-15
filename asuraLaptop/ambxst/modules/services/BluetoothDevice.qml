import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string address: ""
    property string name: "Unknown"
    property string icon: "bluetooth"
    property bool paired: false
    property bool connected: false
    property bool trusted: false
    property int battery: -1
    property bool batteryAvailable: battery >= 0
    property bool connecting: false

    signal infoUpdated()

    // Connect with auto-trust for new devices
    function connect() {
        connecting = true;
        if (!trusted) {
            // Trust first, then connect
            trustThenConnectProcess.command = ["bash", "-c", `bluetoothctl trust ${address} && bluetoothctl connect ${address}`];
            trustThenConnectProcess.running = true;
        } else {
            BluetoothService.connectDevice(address);
        }
    }

    function disconnect() {
        BluetoothService.disconnectDevice(address);
    }

    function pair() {
        BluetoothService.pairDevice(address);
    }

    function trust() {
        BluetoothService.trustDevice(address);
    }

    function forget() {
        BluetoothService.removeDevice(address);
    }

    function updateInfo() {
        infoProcess.command = ["bash", "-c", `bluetoothctl info ${address}`];
        infoProcess.running = true;
    }

    property Process trustThenConnectProcess: Process {
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        onExited: (exitCode, exitStatus) => {
            root.connecting = false;
            root.updateInfo();
        }
    }

    property Process infoProcess: Process {
        running: false
        property string buffer: ""
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => {
                infoProcess.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = infoProcess.buffer;
            infoProcess.buffer = "";
            
            const lines = text.split("\n");
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed.startsWith("Paired:")) {
                    root.paired = trimmed.includes("yes");
                } else if (trimmed.startsWith("Connected:")) {
                    root.connected = trimmed.includes("yes");
                    if (root.connected) root.connecting = false;
                } else if (trimmed.startsWith("Trusted:")) {
                    root.trusted = trimmed.includes("yes");
                } else if (trimmed.startsWith("Icon:")) {
                    root.icon = trimmed.split(":")[1]?.trim() || "bluetooth";
                } else if (trimmed.startsWith("Battery Percentage:")) {
                    const match = trimmed.match(/\((\d+)\)/);
                    if (match) {
                        root.battery = parseInt(match[1]) || -1;
                    }
                }
            }
            root.infoUpdated();
        }
    }
}
