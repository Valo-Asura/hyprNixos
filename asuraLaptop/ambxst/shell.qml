//@ pragma UseQApplication
//@ pragma ShellId Ambxst
//@ pragma DataDir $BASE/Ambxst
//@ pragma StateDir $BASE/Ambxst

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.bar.workspaces
import qs.modules.notifications
import qs.modules.widgets.dashboard.wallpapers
import qs.modules.widgets.settings
import qs.modules.notch
import qs.modules.widgets.overview
import qs.modules.widgets.presets
import qs.modules.services
import qs.modules.corners
import qs.modules.components
import qs.modules.desktop
import qs.modules.lockscreen
import qs.modules.dock
import qs.modules.globals
import qs.config
import "modules/tools"

ShellRoot {
    id: root

    ContextMenu {
        id: contextMenu
        screen: Quickshell.screens[0]
        Component.onCompleted: Visibilities.setContextMenu(contextMenu)
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: wallpaperLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Wallpaper {
                screen: wallpaperLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: desktopLoader
            active: Config.desktop.enabled
            required property ShellScreen modelData
            sourceComponent: Desktop {
                screen: desktopLoader.modelData
            }
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: barLoader
            
            // Force reload when position changes to prevent artifacts
            property bool _active: true
            active: _active

            Connections {
                target: Config.bar
                function onPositionChanged() {
                    barLoader._active = false;
                    barReloadTimer.restart();
                }
            }

            Timer {
                id: barReloadTimer
                interval: 100
                onTriggered: barLoader._active = true
            }

            required property ShellScreen modelData
            sourceComponent: Bar {
                screen: barLoader.modelData
            }
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: notchLoader
            // Delay notch creation to ensure it renders above the bar
            // Both use WlrLayer.Overlay, so we need the notch to be created last
            active: notchDelayTimer.triggered
            required property ShellScreen modelData
            sourceComponent: NotchWindow {
                screen: notchLoader.modelData
            }

            property bool _triggered: false
            Timer {
                id: notchDelayTimer
                property bool triggered: false
                interval: 200  // increased from 50ms — let bar fully render first
                running: true
                onTriggered: triggered = true
            }
        }
    }

    // Overview popup window (separate from notch)
    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: overviewLoader
            // Deferred: loads on first use instead of startup
            active: (Config.overview?.enabled ?? true) && deferredInitTimer.triggered
            required property ShellScreen modelData
            sourceComponent: OverviewPopup {
                screen: overviewLoader.modelData
            }
        }
    }

    // Presets popup window
    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: presetsLoader
            active: deferredInitTimer.triggered  // deferred from startup
            required property ShellScreen modelData
            sourceComponent: PresetsPopup {
                screen: presetsLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: cornersLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: ScreenCorners {
                screen: cornersLoader.modelData
            }
        }
    }

    // Application Dock - only load when enabled and not integrated
    Loader {
        id: dockLoader
        active: (Config.dock?.enabled ?? false) && (Config.dock?.theme ?? "default") !== "integrated"
        sourceComponent: Dock {}
    }

    // Secure lockscreen using WlSessionLock
    WlSessionLock {
        id: sessionLock
        locked: GlobalStates.lockscreenVisible

        LockScreen {
            // WlSessionLockSurface creates automatically for each screen
        }
    }

    GlobalShortcuts {
        id: globalShortcuts
    }

    HyprlandConfig {
        id: hyprlandConfig
    }

    HyprlandKeybinds {
        id: hyprlandKeybinds
    }

    // Ambxst Settings floating window
    Settings {
        id: settingsWindow
    }

    // Screenshot Tool
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotLoader
            active: GlobalStates.screenshotToolVisible
            required property ShellScreen modelData
            sourceComponent: ScreenshotTool {
                targetScreen: screenshotLoader.modelData
            }
        }
    }

    // Screenshot Overlay (Preview)
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotOverlayLoader
            active: deferredInitTimer.triggered  // deferred from startup
            required property ShellScreen modelData
            sourceComponent: ScreenshotOverlay {
                targetScreen: screenshotOverlayLoader.modelData
            }
        }
    }


    // Screen Record Tool (deferred — loads on demand)
    Loader {
        id: screenRecordLoader
        active: GlobalStates.screenRecordToolVisible
        source: "modules/tools/ScreenrecordTool.qml"
        
        Connections {
            target: GlobalStates
            function onScreenRecordToolVisibleChanged() {
                if (screenRecordLoader.status === Loader.Ready) {
                    if (GlobalStates.screenRecordToolVisible) {
                        screenRecordLoader.item.open();
                    } else {
                        screenRecordLoader.item.close();
                    }
                }
            }
        }
        
        Connections {
            target: screenRecordLoader.item
            ignoreUnknownSignals: true
            function onVisibleChanged() {
                if (!screenRecordLoader.item.visible && GlobalStates.screenRecordToolVisible) {
                    GlobalStates.screenRecordToolVisible = false;
                }
            }
        }
    }

    // Mirror Tool (deferred — loads on demand)
    Loader {
        id: mirrorLoader
        active: deferredInitTimer.triggered
        source: "modules/tools/MirrorWindow.qml"
    }

    // Initialize clipboard service at startup to ensure clipboard watching starts immediately
    Connections {
        target: ClipboardService
        function onListCompleted() {
            // Service initialized and ready
        }
    }

    // Deferred init timer — non-critical modules load after 500ms
    Timer {
        id: deferredInitTimer
        property bool triggered: false
        interval: 500
        running: true
        onTriggered: triggered = true
    }

    // Force initialization of control services (deferred to reduce startup load)
    Timer {
        id: serviceInitTimer
        interval: 500
        running: true
        onTriggered: {
            // Reference the services to force their creation
            let _ = NightLightService.active
            _ = GameModeService.toggled
            _ = CaffeineService.inhibit
            _ = WeatherService.dataAvailable
            _ = SystemResources.cpuUsage
            _ = IdleService.lockCmd
        }
    }
}
