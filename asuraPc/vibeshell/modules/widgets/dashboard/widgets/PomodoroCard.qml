import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

StyledRect {
    id: root
    variant: "pane"
    radius: Styling.radius(4)
    implicitHeight: 360

    function selectMode(mode) {
        PomodoroService.setMode(mode);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: Icons.timer
                font.family: Icons.font
                font.pixelSize: 20
                color: Styling.srItem("overprimary")
            }

            Text {
                text: "Pomodoro"
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(1)
                font.bold: true
                color: Colors.overBackground
            }

            Text {
                text: PomodoroService.running ? "Running" : "Ready"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurfaceVariant
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 108
            Layout.preferredHeight: 108

            Canvas {
                id: timerRing
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d");
                    const lineWidth = 7;
                    const cx = width / 2;
                    const cy = height / 2;
                    const radius = Math.min(width, height) / 2 - lineWidth;

                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(Colors.surfaceBright.r, Colors.surfaceBright.g, Colors.surfaceBright.b, 0.35);
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
                    ctx.stroke();

                    ctx.strokeStyle = Styling.srItem("overprimary");
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * PomodoroService.progress);
                    ctx.stroke();
                }

                Connections {
                    target: PomodoroService
                    function onProgressChanged() { timerRing.requestPaint(); }
                    function onModeChanged() { timerRing.requestPaint(); }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: PomodoroService.formatTime(PomodoroService.remainingSeconds)
                    font.family: Config.theme.font
                    font.pixelSize: 26
                    font.bold: true
                    color: Colors.overBackground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: PomodoroService.modeLabel
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.overSurfaceVariant
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "Focus", mode: "focus" },
                    { label: "Short", mode: "short" },
                    { label: "Long", mode: "long" }
                ]

                StyledRect {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Styling.radius(2)
                    variant: PomodoroService.mode === modelData.mode ? "primary" : "common"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: PomodoroService.mode === modelData.mode ? Styling.srItem("primary") : Colors.overBackground
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectMode(modelData.mode)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Styling.radius(2)
                variant: "primary"

                Text {
                    anchors.centerIn: parent
                    text: PomodoroService.running ? "Pause" : "Start"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    color: Styling.srItem("primary")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PomodoroService.toggleRunning()
                }
            }

            StyledRect {
                Layout.preferredWidth: 44
                implicitHeight: 38
                radius: Styling.radius(2)
                variant: resetHover.hovered ? "focus" : "common"

                Text {
                    anchors.centerIn: parent
                    text: Icons.sync
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: Colors.overBackground
                }

                HoverHandler { id: resetHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PomodoroService.reset()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Auto-continue"
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overSurfaceVariant
            }

            Switch {
                checked: PomodoroService.autoContinue
                onToggled: PomodoroService.autoContinue = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Next break"
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overSurfaceVariant
            }

            StyledRect {
                Layout.preferredWidth: 68
                implicitHeight: 28
                radius: Styling.radius(2)
                variant: !PomodoroService.nextBreakLong ? "primary" : "common"

                Text {
                    anchors.centerIn: parent
                    text: "Short"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: !PomodoroService.nextBreakLong ? Styling.srItem("primary") : Colors.overBackground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PomodoroService.nextBreakLong = false
                }
            }

            StyledRect {
                Layout.preferredWidth: 68
                implicitHeight: 28
                radius: Styling.radius(2)
                variant: PomodoroService.nextBreakLong ? "primary" : "common"

                Text {
                    anchors.centerIn: parent
                    text: "Long"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: PomodoroService.nextBreakLong ? Styling.srItem("primary") : Colors.overBackground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PomodoroService.nextBreakLong = true
                }
            }
        }
    }
}
