import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.config

ClippingRectangle {
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property real scale: 1
    property real size: 48 * scale
    property real appIconScale: scale
    property real smallAppIconScale: 0.4
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale
    property bool usingAppIconFallback: false

    implicitWidth: size
    implicitHeight: size
    radius: Styling.radius(-8)
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.urgency == NotificationUrgency.Critical ? Colors.shadow : Colors.surfaceBright
        border.width: root.urgency == NotificationUrgency.Critical ? 2 : 0
        border.color: root.urgency == NotificationUrgency.Critical ? Colors.criticalRed : "transparent"
        radius: root.radius
        visible: root.image == "" && root.appIcon == ""

        Text {
            anchors.centerIn: parent
            text: root.urgency == NotificationUrgency.Critical ? Icons.alert : Icons.bell
            font.family: Icons.font
            font.pixelSize: root.size * 0.5
            color: root.urgency == NotificationUrgency.Critical ? Colors.criticalText : Styling.srItem("overprimary")

            SequentialAnimation on opacity {
                running: root.urgency == NotificationUrgency.Critical
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.5
                    duration: 800
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 0.5
                    to: 1.0
                    duration: 800
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Loader {
        id: appIconLoader
        active: root.image == "" && root.appIcon != ""
        anchors.fill: parent
        sourceComponent: Image {
            id: appIconImage
            anchors.fill: parent
            source: root.appIcon ? "image://icon/" + root.appIcon : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
    }

    // Mostrar imagen de notificación si existe
    Loader {
        id: notifImageLoader
        active: root.image != ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: "transparent"

                Image {
                    id: notifImage
                    anchors.fill: parent
                    source: status === Image.Error && root.appIcon ? "image://icon/" + root.appIcon : root.image
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    onStatusChanged: {
                        if (status === Image.Error && root.appIcon) {
                            source = "image://icon/" + root.appIcon;
                            usingAppIconFallback = true;
                        }
                    }
                }
            }

            // App icon pequeño superpuesto si hay imagen
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != "" && !usingAppIconFallback
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: root.smallAppIconSize
                height: root.smallAppIconSize
                sourceComponent: ClippingRectangle {
                    radius: root.radius * root.smallAppIconScale
                    Image {
                        anchors.fill: parent
                        source: root.appIcon ? "image://icon/" + root.appIcon : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }
            }
        }
    }
}
