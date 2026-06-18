pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme
import qs.modules.widgets.dashboard.metrics

FloatingWindow {
    id: root

    visible: GlobalStates.monitorVisible
    title: "Vibeshell Monitor"
    color: "transparent"
    minimumSize: Qt.size(960, 640)
    maximumSize: Qt.size(960, 640)

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.92)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.38)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Styling.radius(0)
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.82)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 10

                    StyledRect {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        variant: "surface"
                        radius: 17

                        Text {
                            anchors.centerIn: parent
                            text: Icons.cpu
                            font.family: Icons.font
                            font.pixelSize: 17
                            color: Colors.overSurface
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: "Vibeshell System Monitor"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(2)
                            font.weight: Font.Bold
                            color: Styling.srItem("overprimary")
                        }

                        Text {
                            text: "Real-time CPU, GPU, RAM, disk usage, and hardware metrics"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.outline
                        }
                    }

                    Button {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        background: Rectangle {
                            radius: Styling.radius(-4)
                            color: parent.hovered ? Colors.error : "transparent"
                        }

                        contentItem: Text {
                            text: Icons.cancel
                            font.family: Icons.font
                            font.pixelSize: 18
                            color: parent.hovered ? Colors.overError : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: GlobalStates.monitorVisible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                MetricsTab {
                    anchors.fill: parent
                }
            }
        }
    }
}
