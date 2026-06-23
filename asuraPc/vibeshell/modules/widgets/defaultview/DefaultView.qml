import QtQuick
import Quickshell.Io
import qs.modules.theme
import qs.modules.services
import qs.modules.notch
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root
    anchors.top: parent.top
    focus: false

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: {
            GlobalStates.launcherSearchText = "";
            GlobalStates.launcherSelectedIndex = -1;
            Visibilities.setActiveModule("launcher");
        }
    }

    Process {
        id: caffeineCommand
        running: false
    }

    Process {
        id: uptimeReader
        running: true
        command: ["bash", "-lc", "cut -d. -f1 /proc/uptime 2>/dev/null || printf 0"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.uptimeSeconds = parseInt(text.trim()) || 0
        }
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

    function updateActionBead(item, x, y) {
        const p = item.mapToItem(root, x, y);
        hoveredActionPoint = Qt.point(p.x, p.y);
    }

    function setHoverAction(index, item, x, y, panelIndex) {
        hoveredActionIndex = index;
        if (panelIndex >= 0)
            activePanelIndex = panelIndex;
        updateActionBead(item, x, y);
    }

    function panelTitle(index) {
        if (index === 1)
            return "LINK";
        if (index === 2)
            return "WIFI";
        if (index === 3)
            return Qt.formatDate(nowDate, "MMMM yyyy").toUpperCase();
        if (index === 4)
            return "FOCUS";
        if (index === 5)
            return "AWAKE";
        if (index === 6)
            return "SYSTEM";
        if (index === 7)
            return "BLUETOOTH";
        return "";
    }

    function hoverHeightForPanel(index) {
        if (index === 1)
            return 232;
        if (index === 2)
            return 352;
        if (index === 3)
            return 256;
        if (index === 4)
            return 164;
        if (index === 5)
            return 132;
        if (index === 6)
            return 334;
        if (index === 7)
            return 352;
        return 0;
    }

    function formatUptime(seconds) {
        const safe = Math.max(0, seconds || 0);
        const days = Math.floor(safe / 86400);
        const hours = Math.floor((safe % 86400) / 3600);
        const minutes = Math.floor((safe % 3600) / 60);
        if (days > 0)
            return `${days}d ${hours}h`;
        if (hours > 0)
            return `${hours}h ${minutes}m`;
        return `${minutes}m`;
    }

    function compactCpuName(name) {
        let value = (name || "CPU").trim();
        value = value.replace(/\(R\)|\(TM\)|CPU|Processor/gi, "");
        value = value.replace(/12th Gen\s+/i, "12th ");
        value = value.replace(/Intel\s+Core\s+/i, "Intel ");
        value = value.replace(/\s+/g, " ").trim();
        return value || "CPU";
    }

    function compactGpuName(name) {
        let value = (name || "GPU").trim();
        value = value.replace(/NVIDIA\s+GeForce\s+/i, "");
        value = value.replace(/\s+Laptop\s+GPU/i, " Laptop");
        value = value.replace(/\s+Graphics/i, "");
        value = value.replace(/\s+/g, " ").trim();
        return value || "GPU";
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function monthOffset(year, month) {
        const day = new Date(year, month, 1).getDay();
        return day === 0 ? 6 : day - 1;
    }

    property date nowDate: new Date()
    property int uptimeSeconds: 0
    readonly property int notificationPadding: 16
    readonly property int notificationPaddingBottom: Config.notchTheme === "island" ? 20 : 16
    readonly property int notificationPaddingTop: 8
    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0

    property bool notchHovered: false
    property bool railHovered: false
    property bool panelHovered: false
    property bool hoverLatch: false
    property bool isNavigating: false
    property int hoveredActionIndex: -1
    property int activePanelIndex: -1
    property point hoveredActionPoint: Qt.point(width / 2, mainRowHeight + actionRailHeight / 2)
    property real morphCloseness: 1
    readonly property bool actionBeadActive: expandedState && hoveredActionIndex >= 0
    property string ameForm: actionBeadActive ? "dock" : (expandedState ? "soul" : "rest")
    property point amePoint: actionBeadActive ? hoveredActionPoint : Qt.point(expandedState ? width / 2 : (mainRowMargin / 2 + beadSlotWidth / 2), expandedState ? mainRowHeight + actionRailHeight / 2 : mainRowHeight / 2)
    property real ameHeat: actionBeadActive ? 0.45 : 0

    HoverHandler {
        id: contentHoverHandler
    }

    readonly property bool hoverSourceActive: contentHoverHandler.hovered || railHovered || panelHovered || notchHovered || isNavigating
    readonly property bool expandedState: hoverSourceActive || hoverLatch

    onHoverSourceActiveChanged: {
        if (hoverSourceActive) {
            hoverLatch = true;
            hoverGraceTimer.stop();
        } else {
            hoveredActionIndex = -1;
            hoverGraceTimer.restart();
        }
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.nowDate = new Date()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeReader.running = true
    }

    Binding {
        target: GlobalStates
        property: "resourcePreviewVisible"
        value: root.expandedState && root.activePanelIndex === 6
    }

    Timer {
        id: hoverGraceTimer
        interval: 360
        repeat: false
        onTriggered: {
            hoverLatch = false;
            hoveredActionIndex = -1;
            activePanelIndex = -1;
        }
    }

    Timer {
        id: railReleaseTimer
        interval: 220
        repeat: false
        onTriggered: root.railHovered = false
    }

    property real mainRowMargin: (Config.notchTheme === "island" && hasActiveNotifications) ? 64 : 16
    readonly property real beadSlotWidth: 28

    Behavior on mainRowMargin {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    readonly property real mainRowContentWidth: 224 + beadSlotWidth + separator2.width + notifIndicator.width + (mainRow.spacing * 3) + mainRowMargin
    readonly property real mainRowHeight: Config.showBackground ? (Config.notchTheme === "island" ? 36 : 44) : (Config.notchTheme === "island" ? 36 : 40)
    readonly property real actionRailHeight: expandedState && !hasActiveNotifications ? 40 : 0
    readonly property real hoverRailWidth: 238
    readonly property real hoverPanelWidth: 386
    readonly property real hoverPanelHeight: expandedState && !hasActiveNotifications && activePanelIndex > 0 ? hoverHeightForPanel(activePanelIndex) : 0
    readonly property real notificationMinWidth: expandedState ? 420 : 320
    readonly property real notificationContainerHeight: notificationView.implicitHeight + notificationPaddingTop + notificationPaddingBottom

    implicitWidth: Math.round(hasActiveNotifications ? Math.max(notificationMinWidth + (notificationPadding * 2), mainRowContentWidth) : Math.max(mainRowContentWidth, expandedState ? Math.max(hoverRailWidth, hoverPanelWidth) : 0))
    implicitHeight: hasActiveNotifications ? mainRowHeight + notificationContainerHeight : mainRowHeight + actionRailHeight + hoverPanelHeight

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    Behavior on implicitHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Row {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - mainRowMargin
            height: mainRowHeight
            spacing: 4

            Item {
                id: beadSlot
                anchors.verticalCenter: parent.verticalCenter
                width: beadSlotWidth
                height: 32
            }

            Item {
                id: identityWrap
                width: parent.width - beadSlot.width - separator2.width - notifIndicator.width - (parent.spacing * 3)
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: identityRow
                    anchors.centerIn: parent
                    height: 28
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ASURA"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        font.weight: Font.Bold
                        color: Colors.overBackground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "· " + root.formatUptime(root.uptimeSeconds) + " ·"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-3)
                        color: Colors.overSurface
                        opacity: 0.78
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        visible: Battery.available

                        Text {
                            id: chargeBolt
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Battery.available && Battery.isPluggedIn
                            text: Icons.lightning
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: Colors.cyan
                            opacity: Battery.isPluggedIn ? 1 : 0
                            scale: Battery.isPluggedIn ? 1 : 0.92
                            transformOrigin: Item.Center

                            SequentialAnimation on opacity {
                                running: Battery.available && Battery.isPluggedIn
                                loops: Animation.Infinite
                                NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.45; duration: 520; easing.type: Easing.InOutSine }
                            }

                            SequentialAnimation on scale {
                                running: Battery.available && Battery.isPluggedIn
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.18; duration: 420; easing.type: Easing.OutCubic }
                                NumberAnimation { to: 0.94; duration: 520; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.available ? Math.round(Battery.percentage) + "%" : "AC"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-3)
                            font.weight: Font.Bold
                            color: Colors.cyan
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 23
                            height: 12

                            Rectangle {
                                anchors.centerIn: parent
                                width: 32
                                height: 22
                                radius: 11
                                color: Colors.cyan
                                opacity: Battery.isPluggedIn ? 0.14 : 0

                                SequentialAnimation on opacity {
                                    running: Battery.available && Battery.isPluggedIn
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.24; duration: 520; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.06; duration: 620; easing.type: Easing.InOutSine }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 19
                                height: 10
                                radius: 3
                                color: "transparent"
                                border.width: 1
                                border.color: Colors.cyan
                                opacity: Battery.isPluggedIn ? 1 : 0.82

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 2
                                    width: Math.max(2, (parent.width - 4) * Math.max(0.06, Math.min(1, Battery.percentage / 100)))
                                    height: parent.height - 4
                                    radius: 2
                                    color: Colors.cyan
                                    opacity: Battery.isPluggedIn ? 0.88 : 0.72

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Motion.standard
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 19
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 6
                                radius: 1
                                color: Colors.cyan
                                opacity: 0.82
                            }
                        }
                    }
                }
            }

            Separator {
                id: separator2
                vert: true
                anchors.verticalCenter: parent.verticalCenter
            }

            NotificationIndicator {
                id: notifIndicator
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item {
            id: actionRailClip
            width: parent.width
            height: actionRailHeight
            clip: true
            visible: height > 0

            HoverHandler {
                id: railHoverHandler
                onHoveredChanged: root.railHovered = hovered
            }

            Behavior on height {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Math.max(Config.animDuration, 260)
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: actionRail
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                opacity: expandedState && !hasActiveNotifications ? 1 : 0
                scale: 1

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                HoverAction {
                    actionIndex: 1
                    panelIndex: 1
                    icon: Icons.link
                    active: activePanelIndex === 1
                    onTriggered: root.activePanelIndex = root.activePanelIndex === 1 ? -1 : 1
                }

                HoverAction {
                    actionIndex: 2
                    panelIndex: 2
                    icon: NetworkService.wifiEnabled ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                    active: activePanelIndex === 2
                    onTriggered: {
                        root.activePanelIndex = root.activePanelIndex === 2 ? -1 : 2;
                        NetworkService.rescanWifi();
                    }
                }

                HoverAction {
                    actionIndex: 3
                    panelIndex: 3
                    icon: Icons.clock
                    active: activePanelIndex === 3
                    onTriggered: root.activePanelIndex = root.activePanelIndex === 3 ? -1 : 3
                }

                HoverAction {
                    actionIndex: 4
                    panelIndex: 4
                    icon: Icons.timer
                    active: activePanelIndex === 4 || PomodoroService.running
                    onTriggered: root.activePanelIndex = root.activePanelIndex === 4 ? -1 : 4
                }

                HoverAction {
                    actionIndex: 5
                    panelIndex: 5
                    icon: Icons.caffeine
                    active: CaffeineService.inhibit
                    onTriggered: {
                        root.toggleCaffeine();
                        root.activePanelIndex = 5;
                    }
                }

                HoverAction {
                    actionIndex: 6
                    panelIndex: 6
                    icon: Icons.cpu
                    active: activePanelIndex === 6
                    onTriggered: root.activePanelIndex = root.activePanelIndex === 6 ? -1 : 6
                }
            }
        }

        Item {
            id: hoverPanelClip
            width: parent.width
            height: hoverPanelHeight
            clip: false
            visible: height > 0

            HoverHandler {
                id: panelHoverHandler
                onHoveredChanged: root.panelHovered = hovered
            }

            Behavior on height {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            StyledRect {
                id: hoverPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 4
                width: hoverPanelWidth
                height: Math.max(1, parent.height - 8)
                radius: Styling.radius(2)
                variant: "bg"

                Column {
                    id: hoverPanelLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 22
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: activePanelIndex === 3 ? "磨" : "繁"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: Font.Bold
                            color: Styling.srItem("primary")
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.panelTitle(activePanelIndex)
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.letterSpacing: 1.2
                            font.weight: Font.Bold
                            color: Colors.overBackground
                        }

                        Item {
                            width: 1
                            height: 1
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colors.outline
                        opacity: 0.35
                    }

                    Item {
                        id: panelBody
                        width: parent.width
                        height: Math.max(1, hoverPanelLayout.height - 22 - 1 - (hoverPanelLayout.spacing * 2))
                        clip: false

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 1
                            LinkPanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 2
                            WifiPanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 3
                            CalendarPanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 4
                            PomodoroPanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 5
                            AwakePanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 6
                            SystemPreviewPanel { anchors.fill: parent }
                        }

                        PanelSurface {
                            anchors.fill: parent
                            active: activePanelIndex === 7
                            BluetoothPanel { anchors.fill: parent }
                        }
                    }
                }
            }
        }

        Item {
            id: notificationContainer
            width: parent.width
            height: hasActiveNotifications ? notificationContainerHeight : 0
            visible: hasActiveNotifications

            NotchNotificationView {
                id: notificationView
                anchors.fill: parent
                anchors.topMargin: notificationPaddingTop
                anchors.leftMargin: notificationPadding
                anchors.rightMargin: notificationPadding
                anchors.bottomMargin: notificationPaddingBottom
                visible: hasActiveNotifications
                opacity: visible ? 1 : 0
                notchHovered: expandedState
                onIsNavigatingChanged: root.isNavigating = isNavigating

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }

    component HoverAction: StyledRect {
        id: action

        property string icon: ""
        property bool active: false
        property int actionIndex: -1
        property int panelIndex: -1
        signal triggered

        variant: active || actionMouse.containsMouse ? "primary" : "pane"
        width: 38
        height: 34
        radius: Styling.radius(2)

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse) {
                railReleaseTimer.stop();
                root.railHovered = true;
                root.setHoverAction(action.actionIndex, action, action.width / 2, action.height / 2, action.panelIndex)
            } else {
                railReleaseTimer.restart();
            }
            onEntered: {
                railReleaseTimer.stop();
                root.railHovered = true;
                root.setHoverAction(action.actionIndex, action, action.width / 2, action.height / 2, action.panelIndex);
            }
            onPositionChanged: mouse => root.setHoverAction(action.actionIndex, actionMouse, mouse.x, mouse.y, action.panelIndex)
            onClicked: action.triggered()
        }

        Text {
            anchors.centerIn: parent
            text: action.icon
            font.family: Icons.font
            font.pixelSize: 14
            color: action.active || actionMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
        }
    }

    component PanelSurface: Item {
        id: surface

        property bool active: false

        visible: opacity > 0.01
        opacity: active ? 1 : 0
        y: active ? 0 : 8
        scale: active ? 1 : 0.985

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.glide
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Motion.glide
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.glide
                easing.type: Easing.OutCubic
            }
        }
    }

    component PanelRow: Item {
        id: rowRoot

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property string value: ""
        property bool active: false
        property bool showChevron: true
        signal triggered

        width: parent ? parent.width : 320
        height: 42

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: mouse => root.updateActionBead(parent, mouse.x, mouse.y)
            onClicked: rowRoot.triggered()
        }

        Row {
            anchors.fill: parent
            spacing: 10

            Text {
                width: 22
                anchors.verticalCenter: parent.verticalCenter
                text: rowRoot.icon
                font.family: Icons.font
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                color: rowRoot.active ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - 92
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: rowRoot.title
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    font.weight: Font.Bold
                    color: rowRoot.active ? Styling.srItem("primary") : Colors.overBackground
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: rowRoot.subtitle
                    visible: text.length > 0
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    color: Colors.overSurface
                    opacity: 0.72
                    elide: Text.ElideRight
                }
            }

            Text {
                width: 34
                anchors.verticalCenter: parent.verticalCenter
                text: rowRoot.value
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
                font.weight: Font.Bold
                color: rowRoot.active ? Styling.srItem("primary") : Colors.overBackground
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Text {
                width: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.caretRight
                visible: rowRoot.showChevron
                font.family: Icons.font
                font.pixelSize: 12
                color: Colors.overSurface
            }
        }
    }

    component MiniSwitch: StyledRect {
        id: miniSwitch

        property bool checked: false
        signal toggled

        width: 36
        height: 20
        radius: 10
        variant: checked ? "primary" : "pane"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: miniSwitch.toggled()
        }

        Rectangle {
            width: 12
            height: 12
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            x: miniSwitch.checked ? miniSwitch.width - width - 4 : 4
            color: miniSwitch.checked ? Styling.srItem("primary") : Colors.overSurface

            Behavior on x {
                NumberAnimation {
                    duration: Motion.fast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    component LinkPanel: Item {
        Column {
            anchors.fill: parent
            spacing: 8

            Row {
                width: parent.width
                height: 42
                spacing: 10

                PanelRow {
                    width: parent.width - 46
                    icon: NetworkService.wifiEnabled ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                    title: "Network"
                    subtitle: NetworkService.networkName || NetworkService.wifiStatus
                    value: NetworkService.networkStrength > 0 ? String(NetworkService.networkStrength) + "%" : ""
                    active: NetworkService.wifi
                    onTriggered: root.activePanelIndex = 2
                }

                MiniSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: NetworkService.wifiEnabled
                    onToggled: NetworkService.toggleWifi()
                }
            }

            Row {
                width: parent.width
                height: 42
                spacing: 10

                PanelRow {
                    width: parent.width - 46
                    icon: BluetoothService.enabled ? (BluetoothService.connected ? Icons.bluetoothConnected : Icons.bluetooth) : Icons.bluetoothOff
                    title: "Bluetooth"
                    subtitle: BluetoothService.connected ? String(BluetoothService.connectedDevices) + " connected" : "Not connected"
                    active: BluetoothService.enabled
                    onTriggered: {
                        root.activePanelIndex = 7;
                        if (BluetoothService.enabled)
                            BluetoothService.startDiscovery();
                        else
                            BluetoothService.setEnabled(true);
                    }
                }

                MiniSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: BluetoothService.enabled
                    onToggled: BluetoothService.toggle()
                }
            }

            PanelRow {
                icon: Icons.bell
                title: "Inbox"
                subtitle: Notifications.list.length > 0 ? Notifications.list[0].appName + " · " + (Notifications.list[0].summary || Notifications.list[0].body) : "Silence"
                value: Notifications.list.length > 0 ? String(Notifications.list.length) : ""
                showChevron: false
            }
        }
    }

    component WifiPanel: Item {
        Column {
            anchors.fill: parent
            spacing: 5

            Row {
                width: parent.width
                height: 24
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: NetworkService.wifiScanning ? Icons.sync : Icons.arrowCounterClockwise
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: Colors.overBackground

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.rescanWifi()
                    }
                }

                Item {
                    width: parent.width - 64
                    height: 1
                }

                MiniSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: NetworkService.wifiEnabled
                    onToggled: NetworkService.toggleWifi()
                }
            }

            Repeater {
                model: Math.min(5, NetworkService.friendlyWifiNetworks.length)

                delegate: PanelRow {
                    required property int index
                    readonly property var network: NetworkService.friendlyWifiNetworks[index]
                    icon: NetworkService.wifiIconForStrength(network.strength)
                    title: network.ssid
                    subtitle: network.active ? "Connected" : (network.security ? "Secure network" : "Open network")
                    value: String(network.strength) + "%"
                    active: network.active
                    onTriggered: network.active ? NetworkService.disconnectWifiNetwork() : NetworkService.connectToWifiNetwork(network)
                }
            }
        }
    }

    component BluetoothPanel: Item {
        Column {
            anchors.fill: parent
            spacing: 5

            Row {
                width: parent.width
                height: 24
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: BluetoothService.discovering ? Icons.sync : Icons.arrowCounterClockwise
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: Colors.overBackground

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.enabled ? BluetoothService.startDiscovery() : BluetoothService.setEnabled(true)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 64
                    text: BluetoothService.enabled ? (BluetoothService.discovering ? "Scanning" : "Devices") : "Bluetooth disabled"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.Bold
                    color: Colors.overBackground
                    elide: Text.ElideRight
                }

                MiniSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: BluetoothService.enabled
                    onToggled: BluetoothService.toggle()
                }
            }

            Repeater {
                model: Math.min(5, BluetoothService.friendlyDeviceList.length)

                delegate: PanelRow {
                    required property int index
                    readonly property var device: BluetoothService.friendlyDeviceList[index]
                    icon: device.connected ? Icons.bluetoothConnected : Icons.bluetooth
                    title: device.name || "Bluetooth device"
                    subtitle: device.connected ? "Connected" : (device.paired ? "Paired" : "Available")
                    value: device.batteryAvailable ? String(device.battery) + "%" : ""
                    active: device.connected
                    onTriggered: device.connected ? BluetoothService.disconnectDevice(device.address) : BluetoothService.connectDevice(device.address)
                }
            }

            Text {
                visible: BluetoothService.friendlyDeviceList.length === 0
                width: parent.width
                text: BluetoothService.enabled ? "No devices found" : "Turn Bluetooth on to scan"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurface
                opacity: 0.72
                horizontalAlignment: Text.AlignHCenter
                topPadding: 28
            }
        }
    }

    component MetricLine: Item {
        id: metric

        property string icon: ""
        property string title: ""
        property string valueText: ""
        property string subText: ""
        property real value: 0
        property color accent: Styling.srItem("primary")

        width: parent ? parent.width : 320
        height: 36

        Row {
            anchors.fill: parent
            spacing: 9

            Text {
                width: 22
                anchors.verticalCenter: parent.verticalCenter
                text: metric.icon
                font.family: Icons.font
                font.pixelSize: 16
                color: metric.accent
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 80
                spacing: 4

                Row {
                    width: parent.width
                    height: 14
                    spacing: 8

                    Text {
                        width: parent.width - 76
                        text: metric.title
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-3)
                        font.weight: Font.Bold
                        color: Colors.overBackground
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 68
                        text: metric.subText
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-4)
                        color: Colors.overSurface
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.64)
                    border.width: 1
                    border.color: metric.accent

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 2
                        width: Math.max(4, (parent.width - 4) * Math.max(0, Math.min(1, metric.value)))
                        height: 4
                        radius: 2
                        color: metric.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.standard
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Text {
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                text: metric.valueText
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
                font.weight: Font.Bold
                color: Colors.overBackground
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    component SystemPreviewPanel: Item {
        Column {
            anchors.fill: parent
            spacing: 10

            MetricLine {
                icon: Icons.cpu
                title: root.compactCpuName(SystemResources.cpuModel)
                valueText: `${Math.round(SystemResources.cpuUsage || 0)}%`
                subText: SystemResources.cpuTemp >= 0 ? `${SystemResources.cpuTemp}°C` : "temp pending"
                value: (SystemResources.cpuUsage || 0) / 100
                accent: Colors.red
            }

            MetricLine {
                icon: Icons.ram
                title: "Memory"
                valueText: `${Math.round(SystemResources.ramUsage || 0)}%`
                subText: `${(SystemResources.ramUsed / 1024 / 1024).toFixed(1)} / ${(SystemResources.ramTotal / 1024 / 1024).toFixed(1)} GiB`
                value: (SystemResources.ramUsage || 0) / 100
                accent: Colors.cyan
            }

            MetricLine {
                icon: Icons.gpu
                title: root.compactGpuName(SystemResources.gpuNames[0] || "GPU")
                valueText: `${Math.round(SystemResources.gpuUsages[0] || 0)}%`
                subText: (SystemResources.gpuTemps[0] ?? -1) >= 0 ? `${SystemResources.gpuTemps[0]}°C` : "temp pending"
                value: (SystemResources.gpuUsages[0] || 0) / 100
                accent: Colors.green
            }

            MetricLine {
                icon: Icons.disk
                title: "Disk /"
                valueText: `${Math.round(SystemResources.diskUsage["/"] || 0)}%`
                subText: `${((SystemResources.diskUsed["/"] || 0) / 1024 / 1024 / 1024).toFixed(1)} / ${((SystemResources.diskTotal["/"] || 0) / 1024 / 1024 / 1024).toFixed(1)} GB`
                value: (SystemResources.diskUsage["/"] || 0) / 100
                accent: Colors.yellow
            }

            MiniButton {
                width: parent.width
                label: "OPEN FULL MONITOR"
                onTriggered: GlobalStates.monitorVisible = true
            }
        }
    }

    component CalendarPanel: Item {
        id: cal

        readonly property date calDate: root.nowDate
        readonly property int year: calDate.getFullYear()
        readonly property int month: calDate.getMonth()
        readonly property int today: calDate.getDate()
        readonly property int offset: root.monthOffset(year, month)
        readonly property int dayCount: root.daysInMonth(year, month)

        Column {
            anchors.fill: parent
            spacing: 9

            Row {
                width: parent.width
                height: 18
                spacing: 0

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    delegate: Text {
                        required property string modelData
                        width: parent.width / 7
                        text: modelData
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-3)
                        font.weight: Font.Bold
                        color: Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 4
                columnSpacing: 0

                Repeater {
                    model: 35
                    delegate: Item {
                        required property int index
                        width: parent.width / 7
                        height: 24
                        readonly property int dayNum: index - cal.offset + 1
                        readonly property bool inMonth: dayNum > 0 && dayNum <= cal.dayCount
                        readonly property bool isToday: inMonth && dayNum === cal.today

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            color: "transparent"
                            border.width: isToday ? 2 : 0
                            border.color: Styling.srItem("primary")
                        }

                        Text {
                            anchors.centerIn: parent
                            text: inMonth ? String(dayNum) : ""
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            font.weight: isToday ? Font.Bold : Font.Normal
                            color: isToday ? Styling.srItem("primary") : Colors.overBackground
                        }
                    }
                }
            }
        }
    }

    component PomodoroPanel: Item {
        Column {
            anchors.fill: parent
            spacing: 10

            PanelRow {
                icon: Icons.timer
                title: PomodoroService.formatTime(PomodoroService.remainingSeconds)
                subtitle: PomodoroService.modeLabel
                value: PomodoroService.running ? "ON" : "PAUSE"
                active: PomodoroService.running
                showChevron: false
                onTriggered: PomodoroService.toggleRunning()
            }

            Row {
                width: parent.width
                height: 30
                spacing: 8

                MiniButton {
                    label: "FOCUS"
                    active: PomodoroService.mode === "focus"
                    onTriggered: PomodoroService.setMode("focus")
                }

                MiniButton {
                    label: "SHORT"
                    active: PomodoroService.mode === "short"
                    onTriggered: PomodoroService.setMode("short")
                }

                MiniButton {
                    label: "RESET"
                    onTriggered: PomodoroService.reset()
                }
            }
        }
    }

    component AwakePanel: Item {
        Column {
            anchors.fill: parent
            spacing: 10

            PanelRow {
                icon: Icons.caffeine
                title: CaffeineService.inhibit ? "Awake mode on" : "Sleep mode allowed"
                subtitle: CaffeineService.inhibit ? "Shell switching keeps inhibit active" : "Screen lock and suspend are normal"
                value: CaffeineService.inhibit ? "ON" : "OFF"
                active: CaffeineService.inhibit
                showChevron: false
                onTriggered: root.toggleCaffeine()
            }

            MiniButton {
                width: parent.width
                label: CaffeineService.inhibit ? "DISABLE CAFFEINE" : "ENABLE CAFFEINE"
                active: CaffeineService.inhibit
                onTriggered: root.toggleCaffeine()
            }
        }
    }

    component MiniButton: StyledRect {
        id: miniButton

        property string label: ""
        property bool active: false
        signal triggered

        width: 92
        height: 30
        radius: Styling.radius(1)
        variant: active || buttonMouse.containsMouse ? "primary" : "pane"

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: mouse => root.updateActionBead(parent, mouse.x, mouse.y)
            onClicked: miniButton.triggered()
        }

        Text {
            anchors.centerIn: parent
            text: miniButton.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-3)
            font.weight: Font.Bold
            color: miniButton.active || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
        }
    }
}
