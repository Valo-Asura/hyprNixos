pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string mode: "focus"
    property bool running: false
    property bool autoContinue: false
    property bool nextBreakLong: false
    property int remainingSeconds: durationForMode(mode)

    readonly property int focusSeconds: 46 * 60
    readonly property int shortBreakSeconds: 15 * 60
    readonly property int longBreakSeconds: 25 * 60
    readonly property int durationSeconds: durationForMode(mode)
    readonly property real progress: durationSeconds > 0 ? 1.0 - (remainingSeconds / durationSeconds) : 0.0
    readonly property string modeLabel: mode === "focus" ? "Focus" : mode === "short" ? "Short Break" : "Long Break"

    function durationForMode(nextMode) {
        if (nextMode === "short")
            return shortBreakSeconds;
        if (nextMode === "long")
            return longBreakSeconds;
        return focusSeconds;
    }

    function setMode(nextMode) {
        if (nextMode !== "focus" && nextMode !== "short" && nextMode !== "long")
            return;
        mode = nextMode;
        running = false;
        remainingSeconds = durationForMode(nextMode);
    }

    function toggleRunning() {
        running = !running;
    }

    function reset() {
        running = false;
        remainingSeconds = durationForMode(mode);
    }

    function completeCurrentMode() {
        const nextMode = mode === "focus" ? (nextBreakLong ? "long" : "short") : "focus";
        setMode(nextMode);
        running = autoContinue;
    }

    function formatTime(seconds) {
        const safe = Math.max(0, seconds);
        const minutes = Math.floor(safe / 60);
        const secs = safe % 60;
        return String(minutes).padStart(2, "0") + ":" + String(secs).padStart(2, "0");
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running

        onTriggered: {
            if (root.remainingSeconds <= 1) {
                root.remainingSeconds = 0;
                root.completeCurrentMode();
            } else {
                root.remainingSeconds -= 1;
            }
        }
    }
}
