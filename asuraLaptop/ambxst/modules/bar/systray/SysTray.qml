import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.modules.theme
import qs.modules.components

StyledRect {
    variant: "bg"
    id: root

    required property var bar

    // Orientación derivada de la barra
    property bool vertical: bar.orientation === "vertical"

    // Ajustes de tamaño dinámicos según orientación
    height: vertical ? implicitHeight : parent.height
    Layout.preferredWidth: (vertical ? columnLayout.implicitWidth : rowLayout.implicitWidth) + 16
    implicitWidth: (vertical ? columnLayout.implicitWidth : rowLayout.implicitWidth) + 16
    implicitHeight: (vertical ? columnLayout.implicitHeight : rowLayout.implicitHeight) + 16

    RowLayout {
        id: rowLayout
        visible: !root.vertical
        anchors.centerIn: parent
        anchors.margins: 8
        spacing: 8

        Repeater {
            model: SystemTray.items

            SysTrayItem {
                required property SystemTrayItem modelData
                bar: root.bar
                item: modelData
            }
        }
    }

    ColumnLayout {
        id: columnLayout
        visible: root.vertical
        anchors.centerIn: parent
        anchors.margins: 8
        spacing: 8

        Repeater {
            model: SystemTray.items

            SysTrayItem {
                required property SystemTrayItem modelData
                bar: root.bar
                item: modelData
            }
        }
    }
}
