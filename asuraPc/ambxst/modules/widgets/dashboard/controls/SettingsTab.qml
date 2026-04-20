pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import QtQuick.Effects
import qs.modules.components
import qs.modules.services
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300

    property int currentSection: 0  // 0: Network, 1: Bluetooth, 2: Mixer, 3: Effects, 4: Theme, 5: Binds, 6: System, 7: Shell

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Sidebar container with background
        StyledRect {
            id: sidebarContainer
            variant: "common"
            Layout.preferredWidth: 200
            Layout.maximumWidth: 200
            Layout.fillHeight: true
            Layout.fillWidth: false

            Flickable {
                id: sidebarFlickable
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: sidebar.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Sliding highlight behind tabs
                StyledRect {
                    id: tabHighlight
                    variant: "focus"
                    width: parent.width
                    height: 40
                    radius: Styling.radius(-6)
                    z: 0

                    readonly property int tabHeight: 40
                    readonly property int tabSpacing: 4

                    x: 0
                    y: root.currentSection * (tabHeight + tabSpacing)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Column {
                    id: sidebar
                    width: parent.width
                    spacing: 4
                    z: 1

                    Repeater {
                        model: [
                            {
                                icon: Icons.wifiHigh,
                                label: "Network",
                                section: 0,
                                isIcon: true
                            },
                            {
                                icon: Icons.bluetooth,
                                label: "Bluetooth",
                                section: 1,
                                isIcon: true
                            },
                            {
                                icon: Icons.faders,
                                label: "Mixer",
                                section: 2,
                                isIcon: true
                            },
                            {
                                icon: Icons.waveform,
                                label: "Effects",
                                section: 3,
                                isIcon: true
                            },
                            {
                                icon: Icons.paintBrush,
                                label: "Theme",
                                section: 4,
                                isIcon: true
                            },
                            {
                                icon: Icons.keyboard,
                                label: "Binds",
                                section: 5,
                                isIcon: true
                            },
                            {
                                icon: Icons.circuitry,
                                label: "System",
                                section: 6,
                                isIcon: true
                            },
                            {
                                icon: Icons.compositor,
                                label: "Compositor",
                                section: 7,
                                isIcon: true
                            },
                            {
                                icon: Qt.resolvedUrl("../../../../assets/ambxst/ambxst-icon.svg"),
                                label: "Ambxst",
                                section: 8,
                                isIcon: false
                            }
                        ]

                        delegate: Button {
                            id: sidebarButton
                            required property var modelData
                            required property int index

                            width: sidebar.width
                            height: 40
                            flat: true
                            hoverEnabled: true

                            property bool isActive: root.currentSection === sidebarButton.modelData.section

                            background: Rectangle {
                                color: "transparent"
                            }

                            contentItem: Row {
                                spacing: 8

                                // Icon on the left (font icon)
                                Text {
                                    id: iconText
                                    text: sidebarButton.modelData.isIcon ? sidebarButton.modelData.icon : ""
                                    font.family: Icons.font
                                    font.pixelSize: 20
                                    color: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 10
                                    visible: sidebarButton.modelData.isIcon

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                // SVG icon
                                Item {
                                    width: 30
                                    height: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !sidebarButton.modelData.isIcon

                                    Image {
                                        id: svgIcon
                                        width: 20
                                        height: 20
                                        anchors.centerIn: parent
                                        anchors.horizontalCenterOffset: 5
                                        source: !sidebarButton.modelData.isIcon ? sidebarButton.modelData.icon : ""
                                        sourceSize: Qt.size(width * 2, height * 2)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            brightness: 1.0
                                            colorization: 1.0
                                            colorizationColor: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                        }
                                    }
                                }

                                // Text
                                Text {
                                    text: sidebarButton.modelData.label
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: sidebarButton.isActive ? Font.Bold : Font.Normal
                                    color: sidebarButton.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            onClicked: root.currentSection = sidebarButton.modelData.section
                        }
                    }
                }

                // Scroll wheel navigation between sections
                WheelHandler {
                    enabled: sidebarFlickable.contentHeight <= sidebarFlickable.height
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        if (event.angleDelta.y > 0 && root.currentSection > 0) {
                            root.currentSection--;
                        } else if (event.angleDelta.y < 0 && root.currentSection < 8) {
                            root.currentSection++;
                        }
                    }
                }
            }
        }

        // Content area with animated transitions
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            property int previousSection: 0
            readonly property int maxContentWidth: 480

            // Track section changes for animation direction
            onVisibleChanged: {
                if (visible) {
                    contentArea.previousSection = root.currentSection;
                }
            }

            Connections {
                target: root
                function onCurrentSectionChanged() {
                    contentArea.previousSection = root.currentSection;
                }
            }

            // WiFi Panel
            WifiPanel {
                id: wifiPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 0 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 0 ? 0 : (root.currentSection > 0 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Bluetooth Panel
            BluetoothPanel {
                id: bluetoothPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 1 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 1 ? 0 : (root.currentSection > 1 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Audio Mixer Panel
            AudioMixerPanel {
                id: audioPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 2 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 2 ? 0 : (root.currentSection > 2 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // EasyEffects Panel
            EasyEffectsPanel {
                id: effectsPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 3 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 3 ? 0 : (root.currentSection > 3 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Theme Panel
            ThemePanel {
                id: themePanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 4 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 4 ? 0 : (root.currentSection > 4 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Binds Panel
            BindsPanel {
                id: bindsPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 5 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 5 ? 0 : (root.currentSection > 5 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // System Panel
            SystemPanel {
                id: systemPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 6 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 6 ? 0 : (root.currentSection > 6 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Compositor Panel
            CompositorPanel {
                id: compositorPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 7 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 7 ? 0 : (root.currentSection > 7 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Shell Panel
            ShellPanel {
                id: shellPanel
                anchors.fill: parent
                maxContentWidth: contentArea.maxContentWidth
                visible: opacity > 0
                opacity: root.currentSection === 8 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 8 ? 0 : (root.currentSection > 8 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
