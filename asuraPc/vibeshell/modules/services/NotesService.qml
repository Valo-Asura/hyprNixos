pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string notesDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/vibeshell-notes"
    property string indexPath: notesDir + "/index.json"
    property string settingsPath: notesDir + "/settings.json"
    property bool fileReady: false

    property bool persistentStorage: true
    property bool remindOnLogin: true
    property bool glowWhenUnseen: true
    property var dueReminders: []
    property int unseenCount: 0
    readonly property bool hasUnseenReminders: unseenCount > 0

    property bool loginReminderSent: false
    property int lastUnseenCount: 0

    signal remindersChanged()
    signal reminderPulse()

    Process {
        id: ensureFilesProcess
        running: true
        command: ["bash", "-c", "mkdir -p '" + root.notesDir + "/notes' && if [ ! -s '" + root.indexPath + "' ]; then printf '{\"order\":[],\"notes\":{}}\\n' > '" + root.indexPath + "'; fi && if [ ! -s '" + root.settingsPath + "' ]; then printf '{\"persistentStorage\":true,\"remindOnLogin\":true,\"glowWhenUnseen\":true}\\n' > '" + root.settingsPath + "'; fi"]
        onExited: {
            root.fileReady = true;
            settingsFile.reload();
            indexFile.reload();
            loginReminderTimer.restart();
        }
    }

    FileView {
        id: settingsFile
        path: root.fileReady ? root.settingsPath : ""
        onLoaded: root.loadSettings()
        onFileChanged: reload()
    }

    FileView {
        id: indexFile
        path: root.fileReady ? root.indexPath : ""
        onLoaded: root.loadIndex()
        onFileChanged: reload()
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.fileReady
        onTriggered: root.reload()
    }

    Timer {
        id: loginReminderTimer
        interval: 1500
        repeat: false
        onTriggered: root.checkLoginReminder()
    }

    Process {
        id: notifyProcess
        running: false
        command: []
    }

    function reload() {
        if (!fileReady)
            return;
        settingsFile.reload();
        indexFile.reload();
    }

    function loadSettings() {
        try {
            const raw = settingsFile.text();
            const data = raw && raw.trim().length > 0 ? JSON.parse(raw) : {};
            persistentStorage = data.persistentStorage !== false;
            remindOnLogin = data.remindOnLogin !== false;
            glowWhenUnseen = data.glowWhenUnseen !== false;
        } catch (e) {
            persistentStorage = true;
            remindOnLogin = true;
            glowWhenUnseen = true;
        }
    }

    function saveSettings() {
        if (!fileReady)
            return;
        settingsFile.setText(JSON.stringify({
            persistentStorage: persistentStorage,
            remindOnLogin: remindOnLogin,
            glowWhenUnseen: glowWhenUnseen
        }, null, 2));
    }

    function setPersistentStorage(enabled) {
        persistentStorage = enabled;
        saveSettings();
        loadIndex();
    }

    function setRemindOnLogin(enabled) {
        remindOnLogin = enabled;
        saveSettings();
    }

    function setGlowWhenUnseen(enabled) {
        glowWhenUnseen = enabled;
        saveSettings();
    }

    function parseIndex() {
        try {
            const raw = indexFile.text();
            if (!raw || raw.trim().length === "")
                return { order: [], notes: {} };
            const data = JSON.parse(raw);
            return {
                order: data.order || [],
                notes: data.notes || {}
            };
        } catch (e) {
            return { order: [], notes: {} };
        }
    }

    function loadIndex() {
        if (!persistentStorage) {
            dueReminders = [];
            unseenCount = 0;
            remindersChanged();
            return;
        }

        const now = Date.now();
        const data = parseIndex();
        const due = [];

        for (let i = 0; i < data.order.length; i++) {
            const id = data.order[i];
            const note = data.notes[id];
            if (!note || !note.reminderEnabled || !note.reminderAt)
                continue;

            const reminderTime = Date.parse(note.reminderAt);
            if (isNaN(reminderTime) || reminderTime > now)
                continue;

            due.push({
                id: id,
                title: note.title || "Untitled Note",
                reminderAt: note.reminderAt,
                reminderSeen: note.reminderSeen === true
            });
        }

        const previousUnseen = unseenCount;
        dueReminders = due;
        unseenCount = due.filter(note => !note.reminderSeen).length;
        remindersChanged();

        if (unseenCount !== previousUnseen)
            reminderPulse();
        if (unseenCount > previousUnseen && previousUnseen >= 0)
            sendReminderNotification(false);
    }

    function checkLoginReminder() {
        if (loginReminderSent || !remindOnLogin || unseenCount <= 0)
            return;
        loginReminderSent = true;
        sendReminderNotification(true);
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function sendReminderNotification(fromLogin) {
        if (unseenCount <= 0)
            return;

        const unseen = dueReminders.filter(note => !note.reminderSeen);
        const summary = fromLogin ? "Notes waiting from last session" : "Note reminder";
        const body = unseen.length === 1
            ? unseen[0].title
            : unseen.length + " notes need attention";

        notifyProcess.command = [
            "bash",
            "-lc",
            "command -v notify-send >/dev/null && notify-send " + shellQuote(summary) + " " + shellQuote(body) + " || true"
        ];
        notifyProcess.running = true;
    }

    function markAllSeen() {
        if (!fileReady || unseenCount <= 0)
            return;

        const now = Date.now();
        const data = parseIndex();
        let changed = false;

        for (let i = 0; i < data.order.length; i++) {
            const id = data.order[i];
            const note = data.notes[id];
            if (!note || !note.reminderEnabled || !note.reminderAt)
                continue;

            const reminderTime = Date.parse(note.reminderAt);
            if (!isNaN(reminderTime) && reminderTime <= now && note.reminderSeen !== true) {
                note.reminderSeen = true;
                changed = true;
            }
        }

        if (changed) {
            indexFile.setText(JSON.stringify(data, null, 2));
            indexFile.reload();
        }
    }

    function markSeen(noteId) {
        if (!fileReady || !noteId)
            return;

        const data = parseIndex();
        if (data.notes[noteId] && data.notes[noteId].reminderSeen !== true) {
            data.notes[noteId].reminderSeen = true;
            indexFile.setText(JSON.stringify(data, null, 2));
            indexFile.reload();
        }
    }

    function snooze(noteId, minutes) {
        if (!fileReady || !noteId)
            return;

        const data = parseIndex();
        if (data.notes[noteId]) {
            const delay = Math.max(1, Number(minutes || 10));
            data.notes[noteId].reminderEnabled = true;
            data.notes[noteId].reminderAt = new Date(Date.now() + delay * 60000).toISOString();
            data.notes[noteId].reminderSeen = false;
            indexFile.setText(JSON.stringify(data, null, 2));
            indexFile.reload();
        }
    }

    function done(noteId) {
        if (!fileReady || !noteId)
            return;

        const data = parseIndex();
        if (data.notes[noteId]) {
            data.notes[noteId].reminderEnabled = false;
            data.notes[noteId].reminderSeen = true;
            indexFile.setText(JSON.stringify(data, null, 2));
            indexFile.reload();
        }
    }
}
