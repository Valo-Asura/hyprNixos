import QtQuick
import Quickshell.Services.Mpris
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

    // Layout constants
    readonly property int notificationPadding: 16
    readonly property int notificationPaddingBottom: Config.notchTheme === "island" ? 20 : 16
    readonly property int notificationPaddingTop: 8

    // State
    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    property bool notchHovered: false
    property bool hoverLatch: false
    property bool isNavigating: false

    HoverHandler {
        id: contentHoverHandler
    }

    readonly property bool hoverSourceActive: contentHoverHandler.hovered || notchHovered || isNavigating || Visibilities.playerMenuOpen
    readonly property bool expandedState: hoverSourceActive || hoverLatch

    onHoverSourceActiveChanged: {
        if (hoverSourceActive) {
            hoverLatch = true;
            hoverGraceTimer.stop();
        } else {
            hoverGraceTimer.restart();
        }
    }

    Timer {
        id: hoverGraceTimer
        interval: 300
        repeat: false
        onTriggered: hoverLatch = false
    }

    property real mainRowMargin: (Config.notchTheme === "island" && hasActiveNotifications) ? 64 : 16

    Behavior on mainRowMargin {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    // Computed dimensions
    readonly property real mainRowContentWidth: 200 + userInfo.width + separator1.width + separator2.width + notifIndicator.width + (mainRow.spacing * 4) + mainRowMargin
    readonly property real mainRowHeight: Config.showBackground ? (Config.notchTheme === "island" ? 36 : 44) : (Config.notchTheme === "island" ? 36 : 40)
    readonly property real actionRailHeight: expandedState && !hasActiveNotifications ? 44 : 0
    readonly property real hoverRailWidth: 430
    readonly property real notificationMinWidth: expandedState ? 420 : 320
    readonly property real notificationContainerHeight: notificationView.implicitHeight + notificationPaddingTop + notificationPaddingBottom

    implicitWidth: Math.round(hasActiveNotifications ? Math.max(notificationMinWidth + (notificationPadding * 2), mainRowContentWidth) : Math.max(mainRowContentWidth, expandedState ? hoverRailWidth : 0))

    implicitHeight: hasActiveNotifications ? mainRowHeight + notificationContainerHeight : mainRowHeight + actionRailHeight

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Math.max(Config.animDuration, 260)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Math.max(Config.animDuration, 260)
            easing.type: Easing.OutCubic
        }
    }

    Keys.onPressed: event => {
        if (expandedState && activePlayer) {
            if (event.key === Qt.Key_Space) {
                activePlayer.togglePlaying();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left && activePlayer.canSeek) {
                activePlayer.position = Math.max(0, activePlayer.position - 10);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right && activePlayer.canSeek) {
                activePlayer.position = Math.min(activePlayer.length, activePlayer.position + 10);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up && activePlayer.canGoPrevious) {
                activePlayer.previous();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down && activePlayer.canGoNext) {
                activePlayer.next();
                event.accepted = true;
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // mainRow container
        Row {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - mainRowMargin
            height: mainRowHeight
            spacing: 4

            UserInfo {
                id: userInfo
                anchors.verticalCenter: parent.verticalCenter
            }

            Separator {
                id: separator1
                vert: true
                anchors.verticalCenter: parent.verticalCenter
            }

            CompactPlayer {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - userInfo.width - separator1.width - separator2.width - notifIndicator.width - (parent.spacing * 4)
                height: 32
                player: activePlayer
                notchHovered: expandedState
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
                spacing: 8
                opacity: expandedState && !hasActiveNotifications ? 1 : 0
                scale: expandedState && !hasActiveNotifications ? 1 : 0.94

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Math.max(Config.animDuration, 220)
                        easing.type: Easing.OutCubic
                    }
                }

                HoverAction {
                    icon: Icons.launch
                    label: "Apps"
                    active: Visibilities.currentActiveModule === "launcher"
                    onTriggered: {
                        GlobalStates.launcherSearchText = "";
                        GlobalStates.launcherSelectedIndex = -1;
                        Visibilities.setActiveModule("launcher");
                    }
                }

                HoverAction {
                    icon: Icons.shutdown
                    label: "Power"
                    active: Visibilities.currentActiveModule === "powermenu"
                    onTriggered: Visibilities.setActiveModule("powermenu")
                }

                HoverAction {
                    icon: Icons.toolbox
                    label: "Tools"
                    active: Visibilities.currentActiveModule === "tools"
                    onTriggered: Visibilities.setActiveModule("tools")
                }

                HoverAction {
                    icon: Icons.gear
                    label: "Settings"
                    active: GlobalStates.settingsVisible
                    onTriggered: GlobalStates.settingsVisible = !GlobalStates.settingsVisible
                }
            }
        }

        // Notification container with its own padding
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
        property string label: ""
        property bool active: false
        signal triggered

        variant: active || actionMouse.containsMouse ? "primary" : "pane"
        width: 96
        height: 32
        radius: Styling.radius(0)

        Behavior on width {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: action.icon
                font.family: Icons.font
                font.pixelSize: 15
                color: action.active || actionMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: action.label
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.Bold
                color: action.active || actionMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }
        }
    }
}
