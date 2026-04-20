import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

StyledRect {
    id: root

    required property bool isActive
    required property string iconName
    required property string tooltipText
    signal clicked

    property bool isHovered: mouseArea.containsMouse

    variant: {
        if (isActive && isHovered)
            return "primaryfocus";
        if (isActive)
            return "primary";
        if (isHovered)
            return "focus";
        return "pane";
    }

    radius: root.isActive ? Styling.radius(0) : Styling.radius(4)

    Text {
        anchors.centerIn: parent
        text: root.iconName
        color: root.item
        font.family: Icons.font
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
            enabled: Config.animDuration > 0
            ColorAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        StyledToolTip {
            visible: parent.containsMouse
            tooltipText: root.tooltipText
        }
    }
}
