pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget: null
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength: 0

    // Control functions
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        enableWifiProc.running = true;
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        connectProc.command = ["nmcli", "dev", "wifi", "connect", accessPoint.ssid];
        connectProc.running = true;
    }

    function disconnectWifiNetwork(): void {
        if (active) {
            disconnectProc.command = ["nmcli", "connection", "down", active.ssid];
            disconnectProc.running = true;
        }
    }

    function changePassword(network: WifiAccessPoint, password: string): void {
        network.askingPassword = false;
        changePasswordProc.environment = { "PASSWORD": password };
        changePasswordProc.command = ["bash", "-c", `nmcli connection modify "${network.ssid}" wifi-sec.psk "$PASSWORD"`];
        changePasswordProc.running = true;
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    // Helper function for wifi icon based on strength
    function wifiIconForStrength(strength: int): string {
        if (strength > 80) return Icons.wifiHigh;
        if (strength > 55) return Icons.wifiMedium;
        if (strength > 30) return Icons.wifiLow;
        if (strength > 0) return Icons.wifiNone;
        return Icons.wifiOff;
    }

    // Processes
    Process {
        id: enableWifiProc
        running: false
        onExited: root.update()
    }

    Process {
        id: connectProc
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required") && root.wifiConnectTarget) {
                    root.wifiConnectTarget.askingPassword = true;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = (exitCode !== 0);
                root.wifiConnectTarget = null;
            }
        }
    }

    Process {
        id: disconnectProc
        running: false
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: changePasswordProc
        running: false
        onExited: {
            connectProc.running = false;
            if (root.wifiConnectTarget) {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", root.wifiConnectTarget.ssid];
                connectProc.running = true;
            }
        }
    }

    Process {
        id: rescanProcess
        running: false
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                root.wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer: ""
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop();
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected";
                    } else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected";
                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited";
                        }
                    } else if (line.includes("connecting")) {
                        wifiStatus = "connecting";
                    } else if (line.includes("unavailable")) {
                        wifiStatus = "disabled";
                    }
                }
            });
            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data) || 0;
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = data.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                getNetworks.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = getNetworks.buffer;
            getNetworks.buffer = "";
            
            const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
            const rep = new RegExp("\\\\:", "g");
            const rep2 = new RegExp(PLACEHOLDER, "g");

            const allNetworks = text.trim().split("\n").map(n => {
                const net = n.replace(rep, PLACEHOLDER).split(":");
                return {
                    active: net[0] === "yes",
                    strength: parseInt(net[1]) || 0,
                    frequency: parseInt(net[2]) || 0,
                    ssid: net[3] || "",
                    bssid: (net[4] || "").replace(rep2, ":"),
                    security: net[5] || ""
                };
            }).filter(n => n.ssid && n.ssid.length > 0);

            // Group networks by SSID and prioritize connected ones
            const networkMap = new Map();
            for (const network of allNetworks) {
                const existing = networkMap.get(network.ssid);
                if (!existing) {
                    networkMap.set(network.ssid, network);
                } else {
                    if (network.active && !existing.active) {
                        networkMap.set(network.ssid, network);
                    } else if (!network.active && !existing.active) {
                        if (network.strength > existing.strength) {
                            networkMap.set(network.ssid, network);
                        }
                    }
                }
            }

            const wifiNetworks = Array.from(networkMap.values());
            const rNetworks = root.wifiNetworks;

            const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
            for (const network of destroyed)
                rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

            for (const network of wifiNetworks) {
                const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                if (match) {
                    match.lastIpcObject = network;
                } else {
                    rNetworks.push(apComp.createObject(root, {
                        lastIpcObject: network
                    }));
                }
            }
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }

    Component.onCompleted: {
        update();
        wifiStatusProcess.running = true;
    }
}
