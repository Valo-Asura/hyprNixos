import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config
import "../../../services" as LocalServices

StyledRect {
    id: root
    variant: "pane"
    radius: Styling.radius(4)
    implicitHeight: 340

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: Icons.edit
                font.family: Icons.font
                font.pixelSize: 20
                color: Styling.srItem("overprimary")
            }

            Text {
                text: "Notes"
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(1)
                font.bold: true
                color: Colors.overBackground
            }

            Text {
                text: LocalServices.PomodoroNotesService.notes.length + ""
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurfaceVariant
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Styling.radius(2)
                variant: "common"

                TextField {
                    id: newNoteInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    placeholderText: "Add quick note..."
                    color: Colors.overBackground
                    placeholderTextColor: Colors.outline
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    background: null
                    selectByMouse: true
                    onAccepted: {
                        LocalServices.PomodoroNotesService.createNote(text);
                        text = "";
                    }
                }
            }

            StyledRect {
                Layout.preferredWidth: 42
                implicitHeight: 38
                radius: Styling.radius(2)
                variant: addHover.hovered ? "focus" : "primary"

                Text {
                    anchors.centerIn: parent
                    text: Icons.plus
                    font.family: Icons.font
                    font.pixelSize: 19
                    color: Styling.srItem("primary")
                }

                HoverHandler {
                    id: addHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        LocalServices.PomodoroNotesService.createNote(newNoteInput.text);
                        newNoteInput.text = "";
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: LocalServices.PomodoroNotesService.error.length > 0
            text: LocalServices.PomodoroNotesService.error
            color: Colors.error
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-2)
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: notesColumn.implicitHeight

            ColumnLayout {
                id: notesColumn
                width: parent.width
                spacing: 7

                Text {
                    Layout.fillWidth: true
                    visible: LocalServices.PomodoroNotesService.ready && LocalServices.PomodoroNotesService.notes.length === 0
                    text: "No notes yet."
                    color: Colors.outline
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 24
                }

                Repeater {
                    model: LocalServices.PomodoroNotesService.notes

                    StyledRect {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: Styling.radius(2)
                        variant: "common"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            TextField {
                                id: noteField
                                Layout.fillWidth: true
                                text: modelData.text || ""
                                color: Colors.overBackground
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                selectByMouse: true
                                background: null
                                onEditingFinished: LocalServices.PomodoroNotesService.updateNote(modelData.id, text)
                            }

                            Text {
                                text: Icons.trash
                                font.family: Icons.font
                                font.pixelSize: 18
                                color: deleteArea.containsMouse ? Colors.error : Colors.outline
                            }

                            MouseArea {
                                id: deleteArea
                                Layout.preferredWidth: 26
                                Layout.fillHeight: true
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LocalServices.PomodoroNotesService.deleteNote(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
