import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals
import qs.modules.services
import qs.config

import Quickshell.Io

Item {
    id: root

    readonly property string appId: "vibeshell"
    readonly property string ipcPipe: "/tmp/vibeshell_ipc.pipe"

    // High-performance Pipe Listener (Daemon mode)
    // Creates a named pipe and listens for commands continuously
    Process {
        id: pipeListener
        command: ["bash", "-c", "rm -f " + root.ipcPipe + "; mkfifo " + root.ipcPipe + "; tail -f " + root.ipcPipe]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const cmd = data.trim();
                if (cmd !== "") {
                    root.run(cmd);
                }
            }
        }
    }

    Process {
        id: skwdProcess
        command: ["skwd", "wall", "toggle"]
        running: false
    }

    Process {
        id: caffeineCommand
        running: false
    }

    function setCaffeine(next) {
        CaffeineService.inhibit = next;
        caffeineCommand.running = false;
        caffeineCommand.command = ["asura-quickshell-switch", next ? "caffeine-on" : "caffeine-off"];
        caffeineCommand.running = true;
    }

    function run(command) {
        console.log("IPC run command received:", command);
        switch (command) {
        // Dashboard
        case "dashboard-close":
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            break;
        case "notch-launcher":
            toggleNotchLauncher();
            break;
        case "dashboard":
            toggleDashboardTab(0);
            break;
        case "dashboard-widgets":
            toggleDashboardTab(0);
            break;
        case "dashboard-wallpapers":
            skwdProcess.running = false;
            skwdProcess.running = true;
            break;
        case "dashboard-kanban":
            toggleDashboardTab(1);
            break;
        case "dashboard-pomodoro":
            GlobalStates.widgetsTabCurrentIndex = 0;
            toggleDashboardTab(2);
            break;
        case "dashboard-wifi":
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 0 && GlobalStates.widgetsTabCurrentIndex === 5) {
                Visibilities.setActiveModule("");
            } else {
                GlobalStates.dashboardCurrentTab = 0;
                GlobalStates.widgetsTabCurrentIndex = 5;
                NetworkService.rescanWifi();
                Visibilities.setActiveModule("dashboard");
            }
            break;
        case "dashboard-controls":
            toggleDashboardTab(3);
            break;
        case "dashboard-clipboard":
            toggleDashboardWithPrefix(Config.prefix.clipboard + " ");
            break;
        case "dashboard-emoji":
            toggleDashboardWithPrefix(Config.prefix.emoji + " ");
            break;
        case "dashboard-tmux":
            toggleDashboardWithPrefix(Config.prefix.tmux + " ");
            break;
        case "dashboard-notes":
            GlobalStates.notesVisible = !GlobalStates.notesVisible;
            break;
        case "notes-new":
            GlobalStates.notesVisible = true;
            GlobalStates.notesRequestedSection = 0;
            GlobalStates.notesRequestedId = NotesService.createQuickNote();
            break;
        case "reminder-new":
            GlobalStates.notesVisible = true;
            GlobalStates.notesRequestedSection = 1;
            NotesService.createQuickReminder();
            break;

        // System
        case "overview":
            toggleSimpleModule("overview");
            break;
        case "powermenu":
            toggleSimpleModule("powermenu");
            break;
        case "tools":
            toggleSimpleModule("tools");
            break;
        case "config":
            GlobalStates.settingsVisible = !GlobalStates.settingsVisible;
            break;
        case "screenshot":
            GlobalStates.screenshotToolVisible = true;
            break;
        case "screenrecord":
            GlobalStates.screenRecordToolVisible = true;
            break;
        case "caffeine-on":
            setCaffeine(true);
            break;
        case "caffeine-off":
            setCaffeine(false);
            break;
        case "caffeine-toggle":
            setCaffeine(!CaffeineService.inhibit);
            break;
        case "lens":
            Screenshot.captureMode = "lens";
            GlobalStates.screenshotToolVisible = true;
            break;
        case "lockscreen":
            GlobalStates.lockscreenVisible = true;
            break;
        case "gamemode-toggle":
            GameModeService.toggle();
            break;
        case "gamemode-enable":
            GameModeService.toggled = true;
            GameModeService.saveState();
            break;
        case "gamemode-disable":
            GameModeService.toggled = false;
            GameModeService.saveState();
            break;

        // Media
        case "media-seek-backward":
            seekActivePlayer(-mediaSeekStepMs);
            break;
        case "media-seek-forward":
            seekActivePlayer(mediaSeekStepMs);
            break;
        case "media-play-pause":
            if (MprisController.canTogglePlaying)
                MprisController.togglePlaying();
            break;
        case "media-next":
            MprisController.next();
            break;
        case "media-prev":
            MprisController.previous();
            break;
        default:
            console.warn("Unknown IPC command:", command);
        }
    }

    IpcHandler {
        target: "vibeshell"

        function run(command: string) {
            root.run(command);
        }
    }

    function toggleSimpleModule(moduleName) {
        if (Visibilities.currentActiveModule === moduleName) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule(moduleName);
        }
    }

    function toggleDashboardTab(tabIndex) {
        const isActive = Visibilities.currentActiveModule === "dashboard";

        // Special handling for widgets tab (launcher)
        if (tabIndex === 0) {
            if (isActive && GlobalStates.dashboardCurrentTab === 0 && GlobalStates.launcherSearchText === "") {
                // Only toggle off if we're already in launcher without prefix
                Visibilities.setActiveModule("");
                return;
            }

            // Otherwise, always go to launcher (clear any prefix and ensure tab 0)
            GlobalStates.dashboardCurrentTab = 0;
            GlobalStates.launcherSearchText = "";
            GlobalStates.launcherSelectedIndex = -1;
            if (!isActive) {
                Visibilities.setActiveModule("dashboard");
            }
            return;
        }

        // For other tabs, normal toggle behavior
        if (isActive && GlobalStates.dashboardCurrentTab === tabIndex) {
            Visibilities.setActiveModule("");
            return;
        }

        GlobalStates.widgetsTabCurrentIndex = 0;
        GlobalStates.dashboardCurrentTab = tabIndex;
        if (!isActive) {
            Visibilities.setActiveModule("dashboard");
        }
    }

    function toggleNotchLauncher() {
        const isActive = Visibilities.currentActiveModule === "launcher";

        if (isActive && GlobalStates.launcherSearchText === "") {
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            return;
        }

        GlobalStates.launcherSearchText = "";
        GlobalStates.launcherSelectedIndex = -1;
        GlobalStates.launcherCurrentTab = 0;

        if (!isActive) {
            Visibilities.setActiveModule("launcher");
        }
    }

    function toggleDashboardWithPrefix(prefix) {
        const isActive = Visibilities.currentActiveModule === "dashboard";

        // Check if dashboard is already open with this prefix
        if (isActive && GlobalStates.dashboardCurrentTab === 0 && GlobalStates.launcherSearchText === prefix) {
            // Toggle off - close dashboard
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            return;
        }

        // Always go to widgets tab first
        GlobalStates.dashboardCurrentTab = 0;

        if (!isActive) {
            // Open dashboard first, then set prefix after a brief delay
            Visibilities.setActiveModule("dashboard");
            Qt.callLater(() => {
                GlobalStates.launcherSearchText = prefix;
            });
        } else {
            // Dashboard already open, just set the prefix
            GlobalStates.launcherSearchText = prefix;
        }
    }

    function seekActivePlayer(offset) {
        const player = MprisController.activePlayer;
        if (!player || !player.canSeek) {
            return;
        }

        const maxLength = typeof player.length === "number" && !isNaN(player.length) ? player.length : Number.MAX_SAFE_INTEGER;
        const clamped = Math.max(0, Math.min(maxLength, player.position + offset));
        player.position = clamped;
    }

    GlobalShortcut {
        appid: root.appId
        name: "overview"
        description: "Toggle window overview"

        onPressed: toggleSimpleModule("overview")
    }

    GlobalShortcut {
        appid: root.appId
        name: "powermenu"
        description: "Toggle power menu"

        onPressed: toggleSimpleModule("powermenu")
    }

    GlobalShortcut {
        appid: root.appId
        name: "tools"
        description: "Toggle tools menu"

        onPressed: toggleSimpleModule("tools")
    }

    GlobalShortcut {
        appid: root.appId
        name: "screenshot"
        description: "Open screenshot tool"

        onPressed: GlobalStates.screenshotToolVisible = true
    }

    GlobalShortcut {
        appid: root.appId
        name: "screenrecord"
        description: "Open screen record tool"

        onPressed: GlobalStates.screenRecordToolVisible = true
    }

    GlobalShortcut {
        appid: root.appId
        name: "lens"
        description: "Open Google Lens (screenshot)"

        onPressed: {
            Screenshot.captureMode = "lens";
            GlobalStates.screenshotToolVisible = true;
        }
    }

    // Dashboard tab shortcuts
    GlobalShortcut {
        appid: root.appId
        name: "dashboard-widgets"
        description: "Open notch app launcher"

        onPressed: toggleNotchLauncher()
    }

    GlobalShortcut {
        appid: root.appId
        name: "notch-launcher"
        description: "Open notch app launcher"

        onPressed: toggleNotchLauncher()
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-clipboard"
        description: "Open dashboard clipboard (via prefix)"

        onPressed: toggleDashboardWithPrefix(Config.prefix.clipboard + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-emoji"
        description: "Open dashboard emoji picker (via prefix)"

        onPressed: toggleDashboardWithPrefix(Config.prefix.emoji + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-tmux"
        description: "Open dashboard tmux sessions (via prefix)"

        onPressed: toggleDashboardWithPrefix(Config.prefix.tmux + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-kanban"
        description: "Open dashboard kanban tab"

        onPressed: toggleDashboardTab(1)
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-pomodoro"
        description: "Open dashboard Pomodoro tab"

        onPressed: toggleDashboardTab(2)
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-wallpapers"
        description: "Open dashboard wallpapers tab"

        onPressed: {
            skwdProcess.running = false;
            skwdProcess.running = true;
        }
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-notes"
        description: "Open Vibeshell Notes"

        onPressed: GlobalStates.notesVisible = !GlobalStates.notesVisible
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-controls"
        description: "Open dashboard controls tab"

        onPressed: toggleDashboardTab(3)
    }

    // Media player shortcuts
    GlobalShortcut {
        appid: root.appId
        name: "media-seek-backward"
        description: "Seek backward in media player"

        onPressed: seekActivePlayer(-mediaSeekStepMs)
    }

    GlobalShortcut {
        appid: root.appId
        name: "media-seek-forward"
        description: "Seek forward in media player"

        onPressed: seekActivePlayer(mediaSeekStepMs)
    }

    GlobalShortcut {
        appid: root.appId
        name: "media-play-pause"
        description: "Toggle play/pause in media player"

        onPressed: {
            if (MprisController.canTogglePlaying) {
                MprisController.togglePlaying();
            }
        }
    }
}
