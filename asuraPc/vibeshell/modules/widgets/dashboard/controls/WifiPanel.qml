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
            height: titlebar.height + vpnCard.height + wireguardImportCard.height + 24

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
                            text: !NetworkService.vpnConfigured ? "No VPN is active" : (NetworkService.vpnProtected ? "VPN active" : "No VPN")
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: vpnCard.item
                            opacity: 0.75
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    StyledRect {
                        id: vpnOffButton
                        variant: vpnToggleArea.containsMouse ? "focus" : "internalbg"
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 36
                        radius: Styling.radius(-2)

                        Text {
                            anchors.centerIn: parent
                            text: NetworkService.vpnDisabling ? "Killing" : "No VPN"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.bold: true
                            color: vpnOffButton.item
                        }

                        MouseArea {
                            id: vpnToggleArea
                            anchors.fill: parent
                            enabled: !NetworkService.vpnDisabling
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkService.disableVpn()
                        }
                    }

                    StyledRect {
                        id: vpnSettingsButton
                        variant: vpnSettingsArea.containsMouse ? "focus" : "internalbg"
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 36
                        radius: Styling.radius(-2)

                        Text {
                            anchors.centerIn: parent
                            text: Icons.gear
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: vpnSettingsButton.item
                        }

                        MouseArea {
                            id: vpnSettingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkService.openVpnSettings()
                        }
                    }
                }
            }

            StyledRect {
                id: wireguardImportCard
                width: root.contentWidth
                height: 154
                anchors.top: vpnCard.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                variant: "pane"
                radius: Styling.radius(0)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: Icons.vpn
                            font.family: Icons.font
                            font.pixelSize: 18
                            color: wireguardImportCard.item
                        }

                        Text {
                            text: "WireGuard setup"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            color: wireguardImportCard.item
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "Copy a WireGuard .conf file, choose a profile name, then import it into NetworkManager."
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        color: wireguardImportCard.item
                        opacity: 0.75
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: wireguardNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            text: NetworkService.vpnName.length > 0 ? NetworkService.vpnName : "asura-wg0"
                            selectByMouse: true
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.overBackground
                            placeholderText: "Profile name"

                            background: StyledRect {
                                variant: wireguardNameInput.activeFocus ? "focus" : "internalbg"
                                radius: Styling.radius(-2)
                            }
                        }

                        StyledRect {
                            id: wireguardImportButton
                            Layout.preferredWidth: 132
                            Layout.preferredHeight: 34
                            variant: wireguardImportArea.containsMouse ? "focus" : "internalbg"
                            radius: Styling.radius(-2)

                            Text {
                                anchors.centerIn: parent
                                text: NetworkService.vpnImporting ? "Importing" : "Import"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.bold: true
                                color: wireguardImportButton.item
                            }

                            MouseArea {
                                id: wireguardImportArea
                                anchors.fill: parent
                                enabled: !NetworkService.vpnImporting
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkService.importWireguardFromClipboard(wireguardNameInput.text)
                            }
                        }
                    }

                    Text {
                        visible: NetworkService.vpnImportMessage.length > 0
                        text: NetworkService.vpnImportMessage
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        color: NetworkService.vpnImportMessage.includes("failed") || NetworkService.vpnImportMessage.includes("does not contain") ? Colors.error : wireguardImportCard.item
                        elide: Text.ElideRight
                        Layout.fillWidth: true
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
