pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services

Singleton {
    id: root

    property var screens: ({})
    property var panels: ({})
    property var bars: ({})
    property var barPanels: ({})
    property var notches: ({})
    property var notchPanels: ({})
    property string currentActiveModule: ""
    property string lastFocusedScreen: ""
    property var contextMenu: null
    property bool playerMenuOpen: false
    readonly property var moduleNames: ["launcher", "dashboard", "overview", "powermenu", "tools", "presets"]

    function setContextMenu(menu) {
        contextMenu = menu;
    }

    function getForScreen(screenName) {
        if (!screens[screenName]) {
            screens[screenName] = screenPropertiesComponent.createObject(root, {
                screenName: screenName
            });
        }
        return screens[screenName];
    }

    function getForActive() {
        if (!Hyprland.focusedMonitor) {
            return null;
        }
        return getForScreen(Hyprland.focusedMonitor.name);
    }

    function registerPanel(screenName, panel) {
        panels[screenName] = panel;
    }

    function unregisterPanel(screenName) {
        delete panels[screenName];
    }

    function registerBar(screenName, barContainer) {
        bars[screenName] = barContainer;
    }

    function unregisterBar(screenName) {
        delete bars[screenName];
    }

    function getBarForScreen(screenName) {
        return bars[screenName] || null;
    }

    function registerBarPanel(screenName, barPanel) {
        barPanels[screenName] = barPanel;
    }

    function unregisterBarPanel(screenName) {
        delete barPanels[screenName];
    }

    function getBarPanelForScreen(screenName) {
        return barPanels[screenName] || null;
    }

    function registerNotch(screenName, notchContainer) {
        notches[screenName] = notchContainer;
    }

    function unregisterNotch(screenName) {
        delete notches[screenName];
    }

    function getNotchForScreen(screenName) {
        return notches[screenName] || null;
    }

    function registerNotchPanel(screenName, notchPanel) {
        notchPanels[screenName] = notchPanel;
    }

    function unregisterNotchPanel(screenName) {
        delete notchPanels[screenName];
    }

    function getNotchPanelForScreen(screenName) {
        return notchPanels[screenName] || null;
    }

    function setActiveModule(moduleName) {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (!focusedMonitor)
            return;

        const focusedScreenName = focusedMonitor.name;

        clearAll();

        if (moduleName) {
            currentActiveModule = moduleName;
            applyActiveModuleToScreen(focusedScreenName);
        } else {
            currentActiveModule = "";
        }

        lastFocusedScreen = focusedScreenName;
    }

    function moveActiveModuleToFocusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (!focusedMonitor || !currentActiveModule)
            return;

        const newFocusedScreen = focusedMonitor.name;
        if (newFocusedScreen === lastFocusedScreen)
            return;

        clearAll();
        applyActiveModuleToScreen(newFocusedScreen);
        lastFocusedScreen = newFocusedScreen;
    }

    Component {
        id: screenPropertiesComponent
        QtObject {
            property string screenName
            property bool launcher: false
            property bool dashboard: false
            property bool overview: false
            property bool powermenu: false
            property bool tools: false
            property bool presets: false
        }
    }

    function clearAll() {
        for (const screenName in screens) {
            const screenProps = screens[screenName];
            for (let i = 0; i < moduleNames.length; i++) {
                screenProps[moduleNames[i]] = false;
            }
        }
    }

    function applyActiveModuleToScreen(screenName) {
        if (!currentActiveModule)
            return;

        const screenProps = getForScreen(screenName);
        if (moduleNames.indexOf(currentActiveModule) !== -1) {
            screenProps[currentActiveModule] = true;
        }
    }

    // Monitor focus changes
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            moveActiveModuleToFocusedScreen();
        }
    }
}
