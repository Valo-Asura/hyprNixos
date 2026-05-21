import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    implicitWidth: 36
    implicitHeight: 36

    Rectangle {
        anchors.centerIn: parent
        width: 34
        height: 34
        radius: 17
        color: Colors.primary
        opacity: NotesService.glowWhenUnseen && NotesService.hasUnseenReminders ? 0.35 : 0
        scale: 0.95
        visible: opacity > 0

        SequentialAnimation on scale {
            running: NotesService.glowWhenUnseen && NotesService.hasUnseenReminders
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.95
                to: 1.12
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 1.12
                to: 0.95
                duration: 900
                easing.type: Easing.InOutSine
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
            }
        }
    }

    ToggleButton {
        anchors.fill: parent
        buttonIcon: NotesService.hasUnseenReminders ? Icons.bellRinging : Icons.notepad
        tooltipText: NotesService.hasUnseenReminders ? "QuickShell Notes - " + NotesService.unseenCount + " unseen reminder(s)" : "QuickShell Notes"
        enableShadow: true

        onToggle: function () {
            GlobalStates.notesVisible = !GlobalStates.notesVisible;
        }
    }
}
