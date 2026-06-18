import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

StyledRect {
    id: root
    
    variant: "bg"
    enableShadow: Config.showBackground
    
    readonly property bool hasActivePlayer: MprisController.activePlayer !== null
    readonly property bool isPlaying: MprisController.isPlaying

    implicitHeight: 36
    implicitWidth: hasActivePlayer ? (isPlaying ? 80 : 44) : 0
    visible: hasActivePlayer

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        // Left side: album art or player icon
        Rectangle {
            id: artContainer
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 12
            color: Colors.surfaceContainer
            clip: true

            // Show Album Art if available
            Image {
                anchors.fill: parent
                source: MprisController.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: source !== ""
            }

            // Fallback player icon if no album art
            Text {
                anchors.centerIn: parent
                text: {
                    if (!MprisController.activePlayer)
                        return Icons.player;
                    const dbusName = (MprisController.activePlayer.dbusName || "").toLowerCase();
                    const desktopEntry = (MprisController.activePlayer.desktopEntry || "").toLowerCase();
                    const identity = (MprisController.activePlayer.identity || "").toLowerCase();

                    if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
                        return Icons.spotify;
                    if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
                        return Icons.chromium;
                    if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
                        return Icons.firefox;
                    if (dbusName.includes("telegram") || desktopEntry.includes("telegram") || identity.includes("telegram"))
                        return Icons.telegram;
                    return Icons.player;
                }
                font.family: Icons.font
                font.pixelSize: 14
                color: Colors.overSurface
                visible: (MprisController.activePlayer?.trackArtUrl ?? "") === ""
            }
        }

        // Right side: visualizer waves (only when playing)
        RowLayout {
            id: waveContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            visible: root.isPlaying

            // 5 visualizer bars
            Repeater {
                model: 5

                delegate: Rectangle {
                    id: bar
                    width: 2
                    radius: 1
                    color: Styling.srItem("overprimary") || Colors.primary
                    Layout.alignment: Qt.AlignVCenter

                    // Height will animate
                    property real targetHeight: 4
                    implicitHeight: targetHeight

                    Behavior on targetHeight {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Timer to change the height randomly when playing
                    Timer {
                        running: root.isPlaying && waveContainer.visible
                        interval: 120 + index * 20
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            bar.targetHeight = 4 + Math.random() * 14;
                        }
                    }
                }
            }
        }

        // Static icon when paused
        Text {
            text: Icons.waveform
            font.family: Icons.font
            font.pixelSize: 12
            color: Colors.overSurfaceVariant
            visible: !root.isPlaying && root.hasActivePlayer
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                // Right click: toggle dashboard widgets tab
                if (Visibilities.currentActiveModule === "dashboard") {
                    Visibilities.setActiveModule("");
                } else {
                    Visibilities.setActiveModule("dashboard");
                    GlobalStates.widgetsTabCurrentIndex = 0; // launcher/widgets
                }
            } else {
                // Left click: play/pause
                MprisController.togglePlaying();
            }
        }

        StyledToolTip {
            visible: parent.containsMouse
            tooltipText: MprisController.activePlayer ? `${MprisController.activePlayer.trackTitle} - ${MprisController.activePlayer.trackArtist}` : "Media Control"
        }
    }
}
