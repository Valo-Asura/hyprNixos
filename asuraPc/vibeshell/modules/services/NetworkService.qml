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
    property bool vpnConfigured: false
    property bool vpnActive: false
    readonly property bool vpnProtected: vpnConfigured && vpnActive
    property string vpnName: ""
    property string vpnStatus: "unconfigured"
    property bool vpnImporting: vpnImportProc.running
    property bool vpnDisabling: vpnDisableProc.running
    property string vpnImportMessage: ""

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

    function openVpnSettings() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    function importWireguardFromClipboard(profileName: string): void {
        const name = profileName && profileName.trim().length > 0 ? profileName.trim() : "asura-wg0";
        vpnImportMessage = "Importing WireGuard profile...";
        vpnImportProc.environment = ({ VPN_NAME: name });
        vpnImportProc.command = ["bash", "-lc",
            "set -euo pipefail\n" +
            "name=\"${VPN_NAME:-asura-wg0}\"\n" +
            "tmp=\"${XDG_RUNTIME_DIR:-/tmp}/vibeshell-wireguard-import.conf\"\n" +
            "umask 077\n" +
            "if command -v wl-paste >/dev/null 2>&1; then\n" +
            "  wl-paste --type text/plain > \"$tmp\" 2>/dev/null || wl-paste > \"$tmp\"\n" +
            "else\n" +
            "  echo 'wl-paste is not installed' >&2\n" +
            "  exit 2\n" +
            "fi\n" +
            "if ! grep -q '^\\[Interface\\]' \"$tmp\" || ! grep -q '^\\[Peer\\]' \"$tmp\"; then\n" +
            "  rm -f \"$tmp\"\n" +
            "  echo 'Clipboard does not contain a WireGuard .conf file' >&2\n" +
            "  exit 3\n" +
            "fi\n" +
            "existing=$(nmcli -t -f NAME,TYPE c show | awk -F: -v name=\"$name\" '$1==name && ($2==\"wireguard\" || $2==\"vpn\"){print $1; exit}')\n" +
            "[ -n \"$existing\" ] && nmcli connection delete \"$existing\" >/dev/null 2>&1 || true\n" +
            "nmcli connection import type wireguard file \"$tmp\" >/dev/null\n" +
            "imported=$(nmcli -t -f NAME,TYPE c show | awk -F: '$2==\"wireguard\"{name=$1} END{print name}')\n" +
            "rm -f \"$tmp\"\n" +
            "[ -n \"$imported\" ] || { echo 'NetworkManager did not create a WireGuard profile' >&2; exit 4; }\n" +
            "nmcli connection modify \"$imported\" connection.id \"$name\" connection.autoconnect no wireguard.mtu 1280 wireguard.peer-routes no wireguard.ip4-auto-default-route no wireguard.ip6-auto-default-route no ipv4.never-default yes ipv6.method disabled ipv6.never-default yes >/dev/null\n" +
            "printf 'Imported %s\\n' \"$name\"\n"
        ];
        vpnImportProc.running = true;
    }

    function disableVpn(): void {
        vpnImportMessage = "Disabling VPN...";
        vpnDisableProc.running = true;
    }

    function toggleVpn(): void {
        if (!vpnConfigured || vpnName.length === 0) {
            openVpnSettings();
            return;
        }

        vpnToggleProc.command = ["nmcli", "connection", vpnActive ? "down" : "up", vpnName];
        vpnToggleProc.running = true;
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
        updateVpnStatus.startCheck();
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
        id: updateVpnStatus
        property string buffer: ""
        command: ["bash", "-lc", "configured=$(nmcli -t -f NAME,TYPE c show | awk -F: '$2==\"wireguard\" || $2==\"vpn\"{print $1; exit}'); active=$(nmcli -t -f NAME,TYPE c show --active | awk -F: '$2==\"wireguard\" || $2==\"vpn\"{print $1; exit}'); printf '%s\\n%s\\n' \"$configured\" \"$active\""]
        running: true
        function startCheck() {
            buffer = "";
            updateVpnStatus.running = true;
        }
        stdout: SplitParser {
            onRead: line => {
                updateVpnStatus.buffer += line + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateVpnStatus.buffer.split("\n");
            const configured = (lines[0] || "").trim();
            const active = (lines[1] || "").trim();
            root.vpnConfigured = configured.length > 0;
            root.vpnActive = active.length > 0;
            root.vpnName = active.length > 0 ? active : configured;
            root.vpnStatus = !root.vpnConfigured ? "unconfigured" : (root.vpnActive ? "active" : "inactive");
        }
    }

    Process {
        id: vpnToggleProc
        running: false
        onExited: root.update()
    }

    Process {
        id: vpnDisableProc
        running: false
        command: ["bash", "-lc",
            "set -u\n" +
            "for name in $(nmcli -t -f NAME,TYPE c show --active | awk -F: '$2==\"wireguard\" || $2==\"vpn\"{print $1}'); do\n" +
            "  nmcli connection down \"$name\" >/dev/null 2>&1 || true\n" +
            "done\n" +
            "nmcli -t -f NAME,TYPE c show | awk -F: '$2==\"wireguard\" || $2==\"vpn\"{print $1}' | while IFS= read -r name; do\n" +
            "  [ -n \"$name\" ] || continue\n" +
            "  nmcli connection modify \"$name\" connection.autoconnect no >/dev/null 2>&1 || true\n" +
            "  nmcli connection modify \"$name\" wireguard.peer-routes no wireguard.ip4-auto-default-route no wireguard.ip6-auto-default-route no wireguard.mtu 1280 ipv4.never-default yes ipv6.method disabled ipv6.never-default yes >/dev/null 2>&1 || true\n" +
            "done\n" +
            "resolvectl flush-caches >/dev/null 2>&1 || true\n" +
            "nmcli general reload >/dev/null 2>&1 || true\n"
        ]
        onExited: exitCode => {
            root.vpnImportMessage = exitCode === 0 ? "VPN disabled; traffic stays on normal internet" : "VPN disable failed";
            root.update();
        }
    }

    Process {
        id: vpnImportProc
        running: false
        stdout: StdioCollector {
            id: vpnImportStdout
        }
        stderr: StdioCollector {
            id: vpnImportStderr
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                root.vpnImportMessage = vpnImportStdout.text.trim() || "WireGuard profile imported";
            } else {
                root.vpnImportMessage = vpnImportStderr.text.trim() || "WireGuard import failed";
            }
            root.update();
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
