import QtQuick
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

Item {
    id: root
    implicitWidth: 24
    implicitHeight: 24

    property int previousNotifCount: 0
    property bool hovered: false

    Item {
        id: shakeContainer
        anchors.centerIn: parent
        width: 24
        height: 24

        SequentialAnimation {
            id: shakeAnimation

            NumberAnimation {
                target: shakeContainer
                property: "rotation"
                to: -15
                duration: 50
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: shakeContainer
                property: "rotation"
                to: 15
                duration: 100
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: shakeContainer
                property: "rotation"
                to: -10
                duration: 80
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: shakeContainer
                property: "rotation"
                to: 10
                duration: 80
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: shakeContainer
                property: "rotation"
                to: 0
                duration: 50
                easing.type: Easing.InQuad
            }
        }

        Text {
            id: iconText
            anchors.centerIn: parent
            text: Notifications.silent ? Icons.bellZ : (Notifications.list.length > 0 ? Icons.bellRinging : Icons.bell)
            textFormat: Text.RichText
            font.family: Icons.font
            font.pixelSize: 18
            color: hovered ? Styling.srItem("overprimary") : (Notifications.list.length > 0 ? Colors.error : Colors.overBackground)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onContainsMouseChanged: root.hovered = containsMouse
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Notifications.silent = !Notifications.silent;
                    return;
                }
                GlobalStates.dashboardCurrentTab = 0;
                GlobalStates.widgetsTabCurrentIndex = 0;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    Connections {
        target: Notifications
        function onPopupListChanged() {
            if (Notifications.popupList.length > previousNotifCount) {
                shakeAnimation.restart();
            }
            previousNotifCount = Notifications.popupList.length;
        }
    }

    Component.onCompleted: {
        previousNotifCount = Notifications.popupList.length;
    }
}
