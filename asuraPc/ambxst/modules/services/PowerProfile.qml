pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.theme

Singleton {
    id: root

    property var availableProfiles: []
    property string currentProfile: ""
    property bool isAvailable: false

    signal profileChanged(string profile)

    Component.onCompleted: {
        checkProc.running = true;
    }

    // Check if powerprofilesctl is available
    Process {
        id: checkProc
        command: ["powerprofilesctl", "version"]
        running: false
        stdout: SplitParser {}
        
        onExited: (exitCode) => {
            isAvailable = exitCode === 0;
            if (!isAvailable) {
                console.warn("PowerProfile: powerprofilesctl not available on this system");
            } else {
                // If available, get current profile and list
                getProc.running = true;
                listProc.running = true;
            }
        }
    }

    // Get current profile
    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const profile = data.trim();
                if (profile && profile.length > 0) {
                    currentProfile = profile;
                }
            }
        }
    }

    // List available profiles
    Process {
        id: listProc
        command: ["powerprofilesctl", "list"]
        running: false
        
        property string fullOutput: ""
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                listProc.fullOutput += data + "\n";
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                const lines = fullOutput.split('\n');
                const profiles = [];
                
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    // Profile lines start with * (active) or spaces and end with :
                    if (line.endsWith(':')) {
                        const profileName = line.replace('*', '').replace(':', '').trim();
                        if (profileName && profileName.length > 0 && profiles.indexOf(profileName) === -1) {
                            profiles.push(profileName);
                        }
                    }
                }
                
                // Sort profiles in the desired order: power-saver, balanced, performance
                const order = ["power-saver", "balanced", "performance"];
                profiles.sort((a, b) => {
                    const indexA = order.indexOf(a);
                    const indexB = order.indexOf(b);
                    // If not in order array, put at end
                    if (indexA === -1) return 1;
                    if (indexB === -1) return -1;
                    return indexA - indexB;
                });
                
                availableProfiles = profiles;
            }
            fullOutput = "";
        }
    }

    // Set profile
    Process {
        id: setProc
        running: false
        stdout: SplitParser {}
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                // Update current profile after successful change
                Qt.callLater(() => {
                    getProc.running = true;
                });
            } else {
                console.warn("PowerProfile: Failed to set profile");
            }
        }
    }

    function updateCurrentProfile() {
        if (isAvailable) {
            getProc.running = true;
        }
    }

    function updateAvailableProfiles() {
        if (isAvailable) {
            availableProfiles = [];
            listProc.running = true;
        }
    }

    function setProfile(profileName) {
        if (!isAvailable) {
            console.warn("PowerProfile: Cannot set profile - service not available");
            return;
        }

        let found = false;
        for (let i = 0; i < availableProfiles.length; i++) {
            if (availableProfiles[i] === profileName) {
                found = true;
                break;
            }
        }

        if (!found) {
            console.warn("PowerProfile: Profile not available:", profileName);
            return;
        }

        setProc.command = ["powerprofilesctl", "set", profileName];
        setProc.running = true;
    }

    // Map profile names to icons
    function getProfileIcon(profileName) {
        if (profileName === "power-saver") return Icons.powerSave;
        if (profileName === "balanced") return Icons.balanced;
        if (profileName === "performance") return Icons.performance;
        return Icons.balanced;
    }

    // Map profile names to display names
    function getProfileDisplayName(profileName) {
        if (profileName === "power-saver") return "Power Save";
        if (profileName === "balanced") return "Balanced";
        if (profileName === "performance") return "Performance";
        return profileName;
    }
}
