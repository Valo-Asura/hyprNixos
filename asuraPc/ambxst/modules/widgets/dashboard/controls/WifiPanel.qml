pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    Component.onCompleted: {
        NetworkService.rescanWifi();
    }

    // Network list - fills entire width for scroll/drag
    ListView {
        id: networkList
        anchors.fill: parent
        clip: true
        spacing: 4

        model: NetworkService.friendlyWifiNetworks

        header: Item {
            width: networkList.width
            height: titlebar.height + vpnCard.height + 16

            PanelTitlebar {
                id: titlebar
                width: root.contentWidth
                anchors.horizontalCenter: parent.horizontalCenter
                title: "Wi-Fi"
                statusText: NetworkService.wifiConnecting ? "Connecting..." : (NetworkService.wifiStatus === "limited" ? "Limited" : "")
                statusColor: NetworkService.wifiStatus === "limited" ? Colors.warning : Styling.srItem("overprimary")
                showToggle: true
                toggleChecked: NetworkService.wifiStatus !== "disabled"

                actions: [
                    {
                        icon: Icons.globe,
                        tooltip: "Open captive portal",
                        enabled: NetworkService.wifiStatus === "limited",
                        onClicked: function () {
                            NetworkService.openPublicWifiPortal();
                        }
                    },
                    {
                        icon: Icons.popOpen,
                        tooltip: "Network settings",
                        onClicked: function () {
                            Quickshell.execDetached(["nm-connection-editor"]);
                        }
                    },
                    {
                        icon: Icons.sync,
                        tooltip: "Rescan networks",
                        enabled: NetworkService.wifiEnabled,
                        loading: NetworkService.wifiScanning,
                        onClicked: function () {
                            NetworkService.rescanWifi();
                        }
                    }
                ]

                onToggleChanged: checked => {
                    NetworkService.enableWifi(checked);
                    if (checked) {
                        NetworkService.rescanWifi();
                    }
                }
            }

            StyledRect {
                id: vpnCard
                width: root.contentWidth
                height: 64
                anchors.top: titlebar.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                variant: NetworkService.vpnProtected ? "primary" : (NetworkService.vpnConfigured ? "common" : "pane")
                radius: Styling.radius(0)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: NetworkService.vpnProtected ? Icons.shieldCheck : (NetworkService.vpnConfigured ? Icons.vpn : Icons.shield)
                        font.family: Icons.font
                        font.pixelSize: 22
                        color: vpnCard.item
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: NetworkService.vpnConfigured ? NetworkService.vpnName : "WireGuard not configured"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            color: vpnCard.item
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: !NetworkService.vpnConfigured ? "Open settings or enable the Nix scaffold after adding peer details" : (NetworkService.vpnProtected ? "Protected" : "Unprotected")
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: vpnCard.item
                            opacity: 0.75
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    StyledRect {
                        id: vpnToggle
                        variant: vpnToggleArea.containsMouse ? "focus" : "internalbg"
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 36
                        radius: Styling.radius(-2)

                        Text {
                            anchors.centerIn: parent
                            text: !NetworkService.vpnConfigured ? "Settings" : (NetworkService.vpnActive ? "Disconnect" : "Connect")
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.bold: true
                            color: vpnToggle.item
                        }

                        MouseArea {
                            id: vpnToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkService.toggleVpn()
                        }
                    }
                }
            }
        }

        delegate: Item {
            required property var modelData
            width: networkList.width
            height: networkItem.height

            WifiNetworkItem {
                id: networkItem
                width: root.contentWidth
                anchors.horizontalCenter: parent.horizontalCenter
                network: parent.modelData
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: networkList.count === 0 && !NetworkService.wifiScanning
            text: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
            font.family: Config.theme.font
            font.pixelSize: Config.theme.fontSize
            color: Colors.overSurfaceVariant
        }
    }
}
