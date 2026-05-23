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
    title: "Vibeshell Notes"
    color: "transparent"
    minimumSize: Qt.size(1040, 700)
    maximumSize: Qt.size(1040, 700)

    property int currentSection: 0
    property int sectionAfterCreate: 0

    onVisibleChanged: {
        if (visible)
            NotesService.reload();
    }

    function createNoteFromHeader() {
        sectionAfterCreate = 0;
        NotesService.createQuickNote();
    }

    function createReminderFromHeader() {
        sectionAfterCreate = 1;
        NotesService.createQuickReminder();
    }

    function isSameLocalDay(left, right) {
        return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    function reminderDateColor(reminderAt, fallbackColor) {
        const reminderTime = Date.parse(reminderAt);
        if (isNaN(reminderTime))
            return fallbackColor;

        const now = new Date();
        const deltaMs = reminderTime - now.getTime();
        if (deltaMs <= 2 * 60 * 60 * 1000)
            return Colors.red;

        const reminderDate = new Date(reminderTime);
        if (isSameLocalDay(reminderDate, now))
            return Colors.yellow;

        const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        if (isSameLocalDay(reminderDate, tomorrow))
            return Colors.green;

        return fallbackColor;
    }

    Connections {
        target: NotesService

        function onNoteCreated(noteId) {
            NotesService.reload();
            root.currentSection = root.sectionAfterCreate;
            if (root.sectionAfterCreate === 0)
                GlobalStates.notesRequestedId = noteId;
        }
    }

    Connections {
        target: GlobalStates

        function onNotesRequestedSectionChanged() {
            if (GlobalStates.notesRequestedSection < 0)
                return;
            root.sectionAfterCreate = GlobalStates.notesRequestedSection;
            root.currentSection = GlobalStates.notesRequestedSection;
            GlobalStates.notesRequestedSection = -1;
        }
    }

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
                            text: "Vibeshell Notes"
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
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 32

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: "+ Note"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.createNoteFromHeader()
                    }

                    Button {
                        Layout.preferredWidth: 116
                        Layout.preferredHeight: 32

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: "+ Reminder"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.createReminderFromHeader()
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
                                {
                                    icon: Icons.notepad,
                                    label: "Notes"
                                },
                                {
                                    icon: Icons.bell,
                                    label: "Reminders"
                                },
                                {
                                    icon: Icons.google,
                                    label: "Calendar"
                                },
                                {
                                    icon: Icons.clip,
                                    label: "Tags"
                                },
                                {
                                    icon: Icons.folder,
                                    label: "Archive"
                                },
                                {
                                    icon: Icons.gear,
                                    label: "Settings"
                                }
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
                            if (root.currentSection === 2)
                                return calendarComponent;
                            if (root.currentSection === 5)
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

        ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "Notes"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(3)
                    font.weight: Font.Bold
                    color: Colors.overSurface
                }

                Button {
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 34

                    background: StyledRect {
                        variant: parent.hovered ? "primary" : "surface"
                        radius: Styling.radius(-4)
                    }

                    contentItem: Text {
                        text: "+ Add note"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.createNoteFromHeader()
                }
            }

            NotesTab {
                Layout.fillWidth: true
                Layout.fillHeight: true
                leftPanelWidth: 300
                prefixIcon: Icons.notepad

                Component.onCompleted: {
                    if (GlobalStates.notesRequestedId)
                        openRequestedNote(GlobalStates.notesRequestedId);
                }
            }
        }
    }

    Component {
        id: remindersComponent

        ColumnLayout {
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "Reminders"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(5)
                    font.weight: Font.Bold
                    color: Colors.overSurface
                }

                Button {
                    Layout.preferredWidth: 128
                    Layout.preferredHeight: 34

                    background: StyledRect {
                        variant: parent.hovered ? "primary" : "surface"
                        radius: Styling.radius(-4)
                    }

                    contentItem: Text {
                        text: "+ Add reminder"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.createReminderFromHeader()
                }
            }

            Text {
                text: NotesService.reminders.length > 0 ? "Future and due reminders are stored locally. Unseen due reminders glow on the bar." : "No reminders yet. Add one to test the reminder clock."
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
                        model: NotesService.reminders

                        StyledRect {
                            id: reminderCard

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 92
                            variant: modelData.due && !modelData.reminderSeen ? "primary" : "surface"
                            radius: Styling.radius(0)
                            backgroundOpacity: modelData.due && !modelData.reminderSeen ? 0.82 : 0.55

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: modelData.due && !modelData.reminderSeen ? Icons.bellRinging : Icons.bell
                                    font.family: Icons.font
                                    font.pixelSize: 20
                                    color: modelData.due && !modelData.reminderSeen ? Colors.overPrimary : Colors.overSurface
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
                                        color: modelData.due && !modelData.reminderSeen ? Colors.overPrimary : Colors.overSurface
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: (modelData.due ? (modelData.reminderSeen ? "Seen · " : "Due now · ") : "Scheduled · ") + new Date(modelData.reminderAt).toLocaleString()
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: root.reminderDateColor(modelData.reminderAt, Colors.outline)
                                        opacity: color === Colors.outline ? 0.82 : 1.0
                                    }
                                }

                                RowLayout {
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            {
                                                label: "Open",
                                                action: "open"
                                            },
                                            {
                                                label: "Snooze",
                                                action: "snooze"
                                            },
                                            {
                                                label: "Seen",
                                                action: "seen"
                                            },
                                            {
                                                label: "Done",
                                                action: "done"
                                            },
                                            {
                                                label: "Google",
                                                action: "google"
                                            }
                                        ]

                                        Button {
                                            required property var modelData
                                            Layout.preferredHeight: 30
                                            Layout.preferredWidth: 70
                                            enabled: modelData.action !== "google" || (NotesService.googleCalendarEnabled && !reminderCard.modelData.googleCalendarSynced)
                                            opacity: enabled ? 1 : 0.48

                                            background: Rectangle {
                                                radius: Styling.radius(-4)
                                                color: parent.hovered ? Colors.surfaceContainerHigh : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.35)
                                            }

                                            contentItem: Text {
                                                text: modelData.action === "google" && reminderCard.modelData.googleCalendarSynced ? "Synced" : modelData.label
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
                                                } else if (modelData.action === "google") {
                                                    NotesService.syncReminderToGoogle(reminderCard.modelData.id);
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
        id: calendarComponent

        ColumnLayout {
            spacing: 14

            Text {
                text: "Google Calendar"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(5)
                font.weight: Font.Bold
                color: Colors.overSurface
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                variant: NotesService.googleCalendarConnected ? "primary" : "surface"
                radius: Styling.radius(0)
                backgroundOpacity: NotesService.googleCalendarConnected ? 0.45 : 0.62

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Text {
                        text: Icons.google
                        font.family: Icons.font
                        font.pixelSize: 32
                        color: NotesService.googleCalendarConnected ? Colors.overPrimary : Colors.overSurface
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: NotesService.googleCalendarConnected ? "Connected to Google Calendar" : "Connect Google Calendar"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(2)
                            font.weight: Font.Bold
                            color: NotesService.googleCalendarConnected ? Colors.overPrimary : Colors.overSurface
                        }

                        Text {
                            Layout.fillWidth: true
                            text: NotesService.googleCalendarStatus
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: NotesService.googleCalendarConnected ? Colors.overPrimary : Colors.outline
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: NotesService.googleCalendarLastSync.length > 0
                            text: "Last agenda sync: " + NotesService.googleCalendarLastSync
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-3)
                            color: Colors.outline
                        }
                    }

                    Button {
                        Layout.preferredWidth: 108
                        Layout.preferredHeight: 34

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: "Connect"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: NotesService.connectGoogleCalendar()
                    }

                    Button {
                        Layout.preferredWidth: 108
                        Layout.preferredHeight: 34

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: NotesService.googleCalendarSyncing ? "Syncing" : "Refresh"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: NotesService.refreshGoogleCalendar()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 34

                    background: StyledRect {
                        variant: parent.hovered ? "primary" : "surface"
                        radius: Styling.radius(-4)
                    }

                    contentItem: Text {
                        text: "Sync local reminders"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: NotesService.syncAllRemindersToGoogle()
                }

                Text {
                    Layout.fillWidth: true
                    text: NotesService.googleCalendarLastPushMessage.length > 0 ? NotesService.googleCalendarLastPushMessage : "Local reminders stay in Vibeshell; synced ones also create Google Calendar popup reminders."
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.outline
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: "Upcoming Google Calendar Events"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(2)
                font.weight: Font.Bold
                color: Colors.overSurface
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: googleEventList.height
                clip: true

                ColumnLayout {
                    id: googleEventList
                    width: parent.width
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        visible: NotesService.googleCalendarEvents.length === 0
                        text: NotesService.googleCalendarConnected ? "No Google Calendar events found for the next 7 days." : "Connect Google Calendar to load live events."
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.outline
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: NotesService.googleCalendarEvents

                        StyledRect {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            variant: "surface"
                            radius: Styling.radius(0)
                            backgroundOpacity: 0.54

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: Icons.google
                                    font.family: Icons.font
                                    font.pixelSize: 19
                                    color: Colors.primary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title || modelData.raw || "Untitled event"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(1)
                                        font.weight: Font.Bold
                                        color: Colors.overSurface
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: [modelData.date, modelData.start, modelData.end].filter(v => v && String(v).length > 0).join(" · ")
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.outline
                                        elide: Text.ElideRight
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

            SettingToggle {
                label: "Google Calendar Sync"
                description: "Enable live Google Calendar agenda and reminder export through gcalcli"
                checked: NotesService.googleCalendarEnabled
                onToggled: checked => NotesService.setGoogleCalendarEnabled(checked)
            }

            SettingToggle {
                label: "Auto Sync New Reminders"
                description: "Create a Google Calendar popup reminder when a new Vibeshell reminder is made"
                checked: NotesService.googleCalendarSyncNewReminders
                onToggled: checked => NotesService.setGoogleCalendarSyncNewReminders(checked)
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                variant: "surface"
                radius: Styling.radius(0)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Google Calendar Name"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            color: Colors.overSurface
                        }

                        TextField {
                            Layout.fillWidth: true
                            text: NotesService.googleCalendarName
                            placeholderText: "primary"
                            font.family: Config.theme.font
                            color: Colors.overSurface
                            selectionColor: Colors.primary
                            selectedTextColor: Colors.overPrimary
                            onEditingFinished: NotesService.setGoogleCalendarName(text)

                            background: Rectangle {
                                radius: Styling.radius(-4)
                                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.38)
                                border.width: parent.activeFocus ? 1 : 0
                                border.color: Colors.primary
                            }
                        }
                    }

                    Button {
                        Layout.preferredWidth: 112
                        Layout.preferredHeight: 34

                        background: StyledRect {
                            variant: parent.hovered ? "primary" : "surface"
                            radius: Styling.radius(-4)
                        }

                        contentItem: Text {
                            text: "Connect"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: NotesService.connectGoogleCalendar()
                    }
                }
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
