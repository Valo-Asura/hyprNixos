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
import qs.modules.widgets.dashboard.notes

FloatingWindow {
    id: root

    visible: GlobalStates.notesVisible
    title: "QuickShell Notes"
    color: "transparent"
    minimumSize: Qt.size(1040, 700)
    maximumSize: Qt.size(1040, 700)

    property int currentSection: 0

    onVisibleChanged: {
        if (visible)
            NotesService.reload();
    }

    Rectangle {
        anchors.fill: parent
        radius: Styling.radius(2)
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.92)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
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
                        variant: NotesService.hasUnseenReminders ? "primary" : "surface"
                        radius: 17
                        enableShadow: NotesService.glowWhenUnseen && NotesService.hasUnseenReminders

                        Text {
                            anchors.centerIn: parent
                            text: NotesService.hasUnseenReminders ? Icons.bellRinging : Icons.notepad
                            font.family: Icons.font
                            font.pixelSize: 17
                            color: NotesService.hasUnseenReminders ? Colors.overPrimary : Colors.overSurface
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: "QuickShell Notes"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(2)
                            font.weight: Font.Bold
                            color: Styling.srItem("overprimary")
                        }

                        Text {
                            text: NotesService.hasUnseenReminders ? `${NotesService.unseenCount} unseen reminder(s) waiting` : "Notes, reminders, tags, and local storage"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.outline
                        }
                    }

                    Button {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 32
                        visible: NotesService.hasUnseenReminders

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: "Mark all seen"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: NotesService.markAllSeen()
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

                        onClicked: GlobalStates.notesVisible = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                StyledRect {
                    Layout.preferredWidth: 76
                    Layout.fillHeight: true
                    variant: "surface"
                    radius: Styling.radius(1)
                    backgroundOpacity: 0.72

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Repeater {
                            model: [
                                { icon: Icons.notepad, label: "Notes" },
                                { icon: Icons.bell, label: "Reminders" },
                                { icon: Icons.clip, label: "Tags" },
                                { icon: Icons.folder, label: "Archive" },
                                { icon: Icons.gear, label: "Settings" }
                            ]

                            Button {
                                id: navButton
                                required property int index
                                required property var modelData

                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 50

                                background: StyledRect {
                                    variant: root.currentSection === navButton.index ? "primary" : (navButton.hovered ? "common" : "transparent")
                                    radius: Styling.radius(-2)
                                }

                                contentItem: ColumnLayout {
                                    spacing: 2

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: navButton.modelData.icon
                                        font.family: Icons.font
                                        font.pixelSize: 17
                                        color: root.currentSection === navButton.index ? Colors.overPrimary : Colors.overSurface
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: navButton.modelData.label
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-4)
                                        color: root.currentSection === navButton.index ? Colors.overPrimary : Colors.outline
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }

                                onClicked: root.currentSection = index
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    variant: "pane"
                    radius: Styling.radius(1)
                    backgroundOpacity: 0.84

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 12
                        sourceComponent: {
                            if (root.currentSection === 0)
                                return notesComponent;
                            if (root.currentSection === 1)
                                return remindersComponent;
                            if (root.currentSection === 4)
                                return settingsComponent;
                            return placeholderComponent;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: notesComponent

        NotesTab {
            leftPanelWidth: 300
            prefixIcon: Icons.notepad

            Component.onCompleted: {
                if (GlobalStates.notesRequestedId)
                    openRequestedNote(GlobalStates.notesRequestedId);
            }
        }
    }

    Component {
        id: remindersComponent

        ColumnLayout {
            spacing: 12

            Text {
                text: "Reminders"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(5)
                font.weight: Font.Bold
                color: Colors.overSurface
            }

            Text {
                text: NotesService.dueReminders.length > 0 ? "Unseen, seen, snoozed, and done states are stored locally." : "No reminders waiting."
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.outline
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: reminderList.height
                clip: true

                ColumnLayout {
                    id: reminderList
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: NotesService.dueReminders

                        StyledRect {
                            id: reminderCard

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 92
                            variant: modelData.reminderSeen ? "surface" : "primary"
                            radius: Styling.radius(0)
                            backgroundOpacity: modelData.reminderSeen ? 0.55 : 0.82

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: modelData.reminderSeen ? Icons.bell : Icons.bellRinging
                                    font.family: Icons.font
                                    font.pixelSize: 20
                                    color: modelData.reminderSeen ? Colors.overSurface : Colors.overPrimary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(1)
                                        font.weight: Font.Bold
                                        color: modelData.reminderSeen ? Colors.overSurface : Colors.overPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: new Date(modelData.reminderAt).toLocaleString()
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: modelData.reminderSeen ? Colors.outline : Colors.overPrimary
                                        opacity: 0.82
                                    }
                                }

                                RowLayout {
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { label: "Open", action: "open" },
                                            { label: "Snooze", action: "snooze" },
                                            { label: "Seen", action: "seen" },
                                            { label: "Done", action: "done" }
                                        ]

                                        Button {
                                            required property var modelData
                                            Layout.preferredHeight: 30
                                            Layout.preferredWidth: 70

                                            background: Rectangle {
                                                radius: Styling.radius(-4)
                                                color: parent.hovered ? Colors.surfaceContainerHigh : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.35)
                                            }

                                            contentItem: Text {
                                                text: modelData.label
                                                font.family: Config.theme.font
                                                font.pixelSize: Styling.fontSize(-2)
                                                color: Colors.overSurface
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: {
                                                if (modelData.action === "open") {
                                                    GlobalStates.notesRequestedId = reminderCard.modelData.id;
                                                    root.currentSection = 0;
                                                } else if (modelData.action === "snooze") {
                                                    NotesService.snooze(reminderCard.modelData.id, 10);
                                                } else if (modelData.action === "seen") {
                                                    NotesService.markSeen(reminderCard.modelData.id);
                                                } else if (modelData.action === "done") {
                                                    NotesService.done(reminderCard.modelData.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsComponent

        ColumnLayout {
            spacing: 14

            Text {
                text: "Reminder Settings"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(5)
                font.weight: Font.Bold
                color: Colors.overSurface
            }

            SettingToggle {
                label: "Persistent Reminders"
                description: "Save notes and reminder states under ~/.local/share/vibeshell-notes"
                checked: NotesService.persistentStorage
                onToggled: checked => NotesService.setPersistentStorage(checked)
            }

            SettingToggle {
                label: "Remind on Login"
                description: "Show pending reminders when Vibeshell starts"
                checked: NotesService.remindOnLogin
                onToggled: checked => NotesService.setRemindOnLogin(checked)
            }

            SettingToggle {
                label: "Glow Bar Icon"
                description: "Pulse the top-bar notes icon while unseen reminders exist"
                checked: NotesService.glowWhenUnseen
                onToggled: checked => NotesService.setGlowWhenUnseen(checked)
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                variant: "surface"
                radius: Styling.radius(0)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Text {
                        text: "Storage Location"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        color: Colors.overSurface
                    }

                    Text {
                        Layout.fillWidth: true
                        text: NotesService.notesDir
                        font.family: Config.theme.monoFont
                        font.pixelSize: Styling.fontSize(-2)
                        color: Colors.outline
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }

    Component {
        id: placeholderComponent

        Item {
            Text {
                anchors.centerIn: parent
                text: "Coming next: tags, archive, and backups"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(2)
                color: Colors.outline
            }
        }
    }

    component SettingToggle: RowLayout {
        id: settingToggle

        property string label: ""
        property string description: ""
        property bool checked: false
        signal toggled(bool checked)

        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: label
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overSurface
            }

            Text {
                Layout.fillWidth: true
                text: description
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.outline
                wrapMode: Text.WordWrap
            }
        }

        Switch {
            checked: settingToggle.checked
            onToggled: settingToggle.toggled(checked)
        }
    }
}
