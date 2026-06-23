import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    implicitWidth: 392
    implicitHeight: panel.implicitHeight

    property real morphCloseness: 1
    property int hoveredControlIndex: -1
    property point hoveredControlPoint: Qt.point(width / 2, 34)
    property string ameForm: hoveredControlIndex >= 0 ? "dock" : "ring"
    property point amePoint: hoveredControlIndex >= 0 ? hoveredControlPoint : Qt.point(width / 2, 34)
    property real ameHeat: hoveredControlIndex >= 0 ? 0.45 : 0.12
    readonly property bool wifiMenuOpen: GlobalStates.dashboardCurrentTab === 0 && GlobalStates.widgetsTabCurrentIndex === 5
    property date now: new Date()

    readonly property var focusedBrightnessMonitor: {
        const focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const found = Brightness.monitors.find(m => m && m.screen && m.screen.name === focusedName);
        return found || (Brightness.monitors.length > 0 ? Brightness.monitors[0] : null);
    }

    function updateControlBead(item, x, y, index) {
        const p = item.mapToItem(root, x, y);
        hoveredControlIndex = index;
        hoveredControlPoint = Qt.point(p.x, p.y);
    }

    function clearControlBead(index) {
        if (hoveredControlIndex === index)
            hoveredControlIndex = -1;
    }

    function formatTime(date) {
        let hours = date.getHours();
        const suffix = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        if (hours === 0)
            hours = 12;
        return String(hours).padStart(2, "0") + ":" + String(date.getMinutes()).padStart(2, "0") + " " + suffix;
    }

    function formatDate(date) {
        return Qt.formatDate(date, "dddd, MMMM d");
    }

    function openWifiMenu() {
        GlobalStates.dashboardCurrentTab = 0;
        GlobalStates.widgetsTabCurrentIndex = 5;
        NetworkService.rescanWifi();
    }

    function closeWifiMenu() {
        GlobalStates.widgetsTabCurrentIndex = 0;
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
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

    function toggleCaffeine() {
        setCaffeine(!CaffeineService.inhibit);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Visibilities.setActiveModule("");
            event.accepted = true;
        }
    }

    StyledRect {
        id: panel
        variant: "bg"
        width: parent.width
        implicitHeight: content.implicitHeight + 28
        radius: Styling.radius(16)
        enableBorder: true

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            Row {
                width: parent.width
                height: 48
                spacing: 10

                Column {
                    width: parent.width - batteryPill.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.formatTime(root.now)
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(8)
                        font.weight: Font.ExtraBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.formatDate(root.now)
                        color: Colors.overSurfaceVariant
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: batteryPill
                    visible: Battery.available
                    variant: Battery.isPluggedIn ? "primary" : "common"
                    width: Battery.available ? 74 : 0
                    height: 38
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Styling.radius(10)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.isPluggedIn ? Icons.lightning : Icons.batteryHigh
                            font.family: Icons.font
                            font.pixelSize: 15
                            color: Battery.isPluggedIn ? Styling.srItem("primary") : Colors.error
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Battery.percentage) + "%"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Bold
                            color: Battery.isPluggedIn ? Styling.srItem("primary") : Colors.overBackground
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10

                QuickTile {
                    controlIndex: 0
                    width: (parent.width - parent.spacing) / 2
                    icon: NetworkService.wifiEnabled ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                    title: "Wi-Fi"
                    subtitle: NetworkService.networkName.length > 0 ? NetworkService.networkName : NetworkService.wifiStatus
                    active: NetworkService.wifiEnabled
                    arrow: true
                    onClicked: NetworkService.toggleWifi()
                    onArrowClicked: root.wifiMenuOpen ? root.closeWifiMenu() : root.openWifiMenu()
                }

                QuickTile {
                    controlIndex: 1
                    width: (parent.width - parent.spacing) / 2
                    icon: BluetoothService.connected ? Icons.bluetoothConnected : (BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothOff)
                    title: "Bluetooth"
                    subtitle: BluetoothService.connected ? BluetoothService.connectedDevices + " connected" : (BluetoothService.enabled ? "On" : "Off")
                    active: BluetoothService.enabled
                    arrow: true
                    onClicked: BluetoothService.toggle()
                    onArrowClicked: {
                        if (BluetoothService.enabled) {
                            if (BluetoothService.discovering)
                                BluetoothService.stopDiscovery();
                            else
                                BluetoothService.startDiscovery();
                        } else {
                            BluetoothService.setEnabled(true);
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: wifiMenuOpen ? Math.min(206, wifiList.contentHeight + wifiHeader.height + 10) : 0
                clip: true
                visible: height > 0

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.standard
                        easing.type: Motion.easeStandard
                    }
                }

                Column {
                    anchors.fill: parent
                    spacing: 6

                    Row {
                        id: wifiHeader
                        width: parent.width
                        height: 26

                        Text {
                            width: parent.width - scanButton.width
                            anchors.verticalCenter: parent.verticalCenter
                            text: NetworkService.wifiScanning ? "SCANNING NETWORKS" : "AVAILABLE NETWORKS"
                            color: Colors.overSurfaceVariant
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-3)
                            font.weight: Font.Bold
                        }

                        MiniIconButton {
                            id: scanButton
                            controlIndex: 2
                            icon: Icons.sync
                            onClicked: NetworkService.rescanWifi()
                        }
                    }

                    ListView {
                        id: wifiList
                        width: parent.width
                        height: parent.height - wifiHeader.height - parent.spacing
                        clip: true
                        spacing: 4
                        model: NetworkService.friendlyWifiNetworks

                        delegate: WifiRow {
                            required property var modelData
                            required property int index
                            width: wifiList.width
                            network: modelData
                            controlIndex: 10 + index
                        }
                    }
                }
            }

            QuickSlider {
                controlIndex: 3
                width: parent.width
                icon: Audio.sink?.audio?.muted ? Icons.speakerX : Icons.speakerHigh
                value: Audio.sink?.audio?.volume ?? 0
                label: "Sound"
                onMoved: value => Audio.setVolume(value)
                onIconClicked: Audio.toggleMute()
            }

            QuickSlider {
                controlIndex: 4
                width: parent.width
                icon: Icons.sun
                value: root.focusedBrightnessMonitor ? root.focusedBrightnessMonitor.brightness : 0
                label: "Display"
                onMoved: value => {
                    if (root.focusedBrightnessMonitor)
                        root.focusedBrightnessMonitor.setBrightness(value);
                }
            }

            StyledRect {
                variant: "common"
                width: parent.width
                height: 88
                radius: Styling.radius(10)

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Item {
                        width: 78
                        height: parent.height

                        Canvas {
                            id: pomoRing
                            anchors.centerIn: parent
                            width: 58
                            height: 58
                            antialiasing: true

                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                const cx = width / 2;
                                const cy = height / 2;
                                const radius = Math.min(width, height) / 2 - 5;
                                ctx.lineWidth = 5;
                                ctx.strokeStyle = Colors.surfaceBright;
                                ctx.beginPath();
                                ctx.arc(cx, cy, radius, 0, Math.PI * 2);
                                ctx.stroke();
                                ctx.strokeStyle = Colors.primary;
                                ctx.beginPath();
                                ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * PomodoroService.progress);
                                ctx.stroke();
                            }

                            Connections {
                                target: PomodoroService
                                function onProgressChanged() { pomoRing.requestPaint(); }
                                function onModeChanged() { pomoRing.requestPaint(); }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.timer
                            font.family: Icons.font
                            font.pixelSize: 20
                            color: Colors.overBackground
                        }
                    }

                    Column {
                        width: parent.width - 88
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 8

                            Column {
                                width: parent.width - 116
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: PomodoroService.formatTime(PomodoroService.remainingSeconds)
                                    color: Colors.overBackground
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(5)
                                    font.weight: Font.Bold
                                }

                                Text {
                                    width: parent.width
                                    text: PomodoroService.modeLabel.toUpperCase()
                                    color: Colors.overSurfaceVariant
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-3)
                                    font.weight: Font.Bold
                                }
                            }

                            MiniButton {
                                controlIndex: 5
                                width: 52
                                label: PomodoroService.running ? "PAUSE" : "START"
                                active: PomodoroService.running
                                onClicked: PomodoroService.toggleRunning()
                            }

                            MiniIconButton {
                                controlIndex: 6
                                icon: Icons.arrowCounterClockwise
                                onClicked: PomodoroService.reset()
                            }
                        }

                        Row {
                            spacing: 6
                            MiniButton {
                                controlIndex: 7
                                label: "FOCUS"
                                active: PomodoroService.mode === "focus"
                                onClicked: PomodoroService.setMode("focus")
                            }
                            MiniButton {
                                controlIndex: 8
                                label: "SHORT"
                                active: PomodoroService.mode === "short"
                                onClicked: PomodoroService.setMode("short")
                            }
                            MiniButton {
                                controlIndex: 9
                                label: "LONG"
                                active: PomodoroService.mode === "long"
                                onClicked: PomodoroService.setMode("long")
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                MiniButton {
                    controlIndex: 20
                    width: (parent.width - parent.spacing * 4) / 5
                    label: "APPS"
                    onClicked: Visibilities.setActiveModule("launcher")
                }

                MiniButton {
                    controlIndex: 21
                    width: (parent.width - parent.spacing * 4) / 5
                    label: "SHOT"
                    onClicked: GlobalStates.screenshotToolVisible = true
                }

                MiniButton {
                    controlIndex: 22
                    width: (parent.width - parent.spacing * 4) / 5
                    label: "REC"
                    onClicked: GlobalStates.screenRecordToolVisible = true
                }

                MiniButton {
                    controlIndex: 23
                    width: (parent.width - parent.spacing * 4) / 5
                    label: CaffeineService.inhibit ? "AWAKE" : "SLEEP"
                    active: CaffeineService.inhibit
                    onClicked: root.toggleCaffeine()
                }

                MiniButton {
                    controlIndex: 24
                    width: (parent.width - parent.spacing * 4) / 5
                    label: "POWER"
                    onClicked: Visibilities.setActiveModule("powermenu")
                }
            }
        }
    }

    component HoverTarget: MouseArea {
        required property int controlIndex
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.updateControlBead(this, width / 2, height / 2, controlIndex)
        onPositionChanged: mouse => root.updateControlBead(this, mouse.x, mouse.y, controlIndex)
        onExited: root.clearControlBead(controlIndex)
    }

    component QuickTile: StyledRect {
        id: tile

        required property int controlIndex
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool arrow: false
        signal clicked
        signal arrowClicked

        height: 82
        variant: active || tileMouse.containsMouse ? "primary" : "common"
        radius: Styling.radius(12)

        HoverTarget {
            id: tileMouse
            controlIndex: tile.controlIndex
            anchors.fill: parent
            onClicked: tile.clicked()
        }

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tile.icon
                font.family: Icons.font
                font.pixelSize: 22
                color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - 58
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: tile.arrow
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 16
                color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant

                HoverTarget {
                    controlIndex: tile.controlIndex
                    anchors.fill: parent
                    onClicked: tile.arrowClicked()
                }
            }
        }
    }

    component QuickSlider: StyledRect {
        id: sliderBox

        required property int controlIndex
        property string icon: ""
        property string label: ""
        property real value: 0
        signal moved(real value)
        signal iconClicked

        height: 42
        variant: "common"
        radius: Styling.radius(10)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                width: 24
                anchors.verticalCenter: parent.verticalCenter
                text: sliderBox.icon
                font.family: Icons.font
                font.pixelSize: 18
                color: Colors.overBackground

                HoverTarget {
                    controlIndex: sliderBox.controlIndex
                    anchors.fill: parent
                    onClicked: sliderBox.iconClicked()
                }
            }

            Item {
                id: track
                width: parent.width - 34
                height: 22
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 7
                    radius: 4
                    color: Colors.surfaceBright
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(7, parent.width * Math.max(0, Math.min(1, sliderBox.value)))
                    height: 7
                    radius: 4
                    color: Colors.primary
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, sliderBox.value)) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 9
                    color: Colors.overBackground
                }

                HoverTarget {
                    controlIndex: sliderBox.controlIndex
                    anchors.fill: parent

                    function commit(mouseX) {
                        const next = Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
                        sliderBox.value = next;
                        sliderBox.moved(next);
                    }

                    onPressed: mouse => commit(mouse.x)
                    onPositionChanged: mouse => {
                        root.updateControlBead(this, mouse.x, mouse.y, controlIndex);
                        if (pressed)
                            commit(mouse.x);
                    }
                    onWheel: wheel => {
                        const next = Math.max(0, Math.min(1, sliderBox.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                        sliderBox.value = next;
                        sliderBox.moved(next);
                    }
                }
            }
        }
    }

    component MiniButton: StyledRect {
        id: button

        required property int controlIndex
        property string label: ""
        property bool active: false
        signal clicked

        width: 64
        height: 30
        variant: active || buttonMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(8)

        HoverTarget {
            id: buttonMouse
            controlIndex: button.controlIndex
            anchors.fill: parent
            onClicked: button.clicked()
        }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.active || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-3)
            font.weight: Font.Bold
        }
    }

    component MiniIconButton: StyledRect {
        id: button

        required property int controlIndex
        property string icon: ""
        signal clicked

        width: 30
        height: 30
        variant: buttonMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(8)

        HoverTarget {
            id: buttonMouse
            controlIndex: button.controlIndex
            anchors.fill: parent
            onClicked: button.clicked()
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            font.family: Icons.font
            font.pixelSize: 16
            color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
        }
    }

    component WifiRow: StyledRect {
        id: row

        required property var network
        required property int controlIndex

        height: 34
        variant: network.active || rowMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(8)

        HoverTarget {
            id: rowMouse
            controlIndex: row.controlIndex
            anchors.fill: parent
            onClicked: {
                if (row.network.active)
                    NetworkService.disconnectWifiNetwork();
                else
                    NetworkService.connectToWifiNetwork(row.network);
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: NetworkService.wifiIconForStrength(row.network.strength)
                font.family: Icons.font
                font.pixelSize: 14
                color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Text {
                width: parent.width - strengthText.width - 34
                anchors.verticalCenter: parent.verticalCenter
                text: row.network.ssid
                color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: row.network.active ? Font.Bold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                id: strengthText
                anchors.verticalCenter: parent.verticalCenter
                text: row.network.strength + "%"
                color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
            }
        }
    }
}
