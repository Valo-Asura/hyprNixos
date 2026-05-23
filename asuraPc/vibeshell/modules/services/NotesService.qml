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
    property bool googleCalendarEnabled: false
    property bool googleCalendarConnected: false
    property bool googleCalendarSyncNewReminders: false
    property bool googleCalendarSyncing: false
    property string googleCalendarName: "primary"
    property string googleCalendarStatus: "Not connected"
    property string googleCalendarLastSync: ""
    property string googleCalendarLastPushMessage: ""
    property var googleCalendarEvents: []
    property var reminders: []
    property var dueReminders: []
    property int unseenCount: 0
    readonly property bool hasUnseenReminders: unseenCount > 0

    property bool loginReminderSent: false
    property int lastUnseenCount: 0

    signal reminderPulse
    signal noteCreated(string noteId)
    signal googleCalendarChanged

    Process {
        id: ensureFilesProcess
        running: true
        command: ["bash", "-c", "mkdir -p '" + root.notesDir + "/notes' && if [ ! -s '" + root.indexPath + "' ]; then printf '{\"order\":[],\"notes\":{}}\\n' > '" + root.indexPath + "'; fi && if [ ! -s '" + root.settingsPath + "' ]; then printf '{\"persistentStorage\":true,\"remindOnLogin\":true,\"glowWhenUnseen\":true,\"googleCalendarEnabled\":false,\"googleCalendarName\":\"primary\",\"googleCalendarSyncNewReminders\":false}\\n' > '" + root.settingsPath + "'; fi"]
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

    Process {
        id: googleStatusProcess
        running: false
        command: []
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.googleCalendarSyncing = false;
            root.applyGoogleStatusOutput(googleStatusProcess.stdout.text, exitCode);
        }
    }

    Process {
        id: googleAgendaProcess
        running: false
        command: []
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.googleCalendarSyncing = false;
            root.applyGoogleAgendaOutput(googleAgendaProcess.stdout.text, exitCode);
        }
    }

    Process {
        id: googleConnectProcess
        running: false
        command: []
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.applyGoogleConnectOutput(googleConnectProcess.stdout.text, exitCode);
        }
    }

    Process {
        id: googlePushProcess
        running: false
        command: []
        property string noteId: ""
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.googleCalendarSyncing = false;
            root.applyGooglePushOutput(googlePushProcess.stdout.text, exitCode, googlePushProcess.noteId);
            googlePushProcess.noteId = "";
        }
    }

    Process {
        id: createNoteProcess
        running: false
        command: []
        property string noteId: ""

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("NotesService: create note failed with code " + exitCode);
            root.reload();
            if (exitCode === 0 && noteId)
                root.noteCreated(noteId);
            if (exitCode === 0 && noteId && root.googleCalendarEnabled && root.googleCalendarSyncNewReminders)
                root.syncReminderToGoogle(noteId);
            noteId = "";
        }
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
            googleCalendarEnabled = data.googleCalendarEnabled === true;
            googleCalendarName = data.googleCalendarName && String(data.googleCalendarName).length > 0 ? String(data.googleCalendarName) : "primary";
            googleCalendarSyncNewReminders = data.googleCalendarSyncNewReminders === true;
            if (googleCalendarEnabled)
                refreshGoogleCalendar();
        } catch (e) {
            persistentStorage = true;
            remindOnLogin = true;
            glowWhenUnseen = true;
            googleCalendarEnabled = false;
            googleCalendarName = "primary";
            googleCalendarSyncNewReminders = false;
        }
    }

    function saveSettings() {
        if (!fileReady)
            return;
        settingsFile.setText(JSON.stringify({
            persistentStorage: persistentStorage,
            remindOnLogin: remindOnLogin,
            glowWhenUnseen: glowWhenUnseen,
            googleCalendarEnabled: googleCalendarEnabled,
            googleCalendarName: googleCalendarName,
            googleCalendarSyncNewReminders: googleCalendarSyncNewReminders
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

    function setGoogleCalendarEnabled(enabled) {
        googleCalendarEnabled = enabled;
        saveSettings();
        if (enabled)
            refreshGoogleCalendar();
        else {
            googleCalendarConnected = false;
            googleCalendarStatus = "Google Calendar sync disabled";
            googleCalendarEvents = [];
            googleCalendarChanged();
        }
    }

    function setGoogleCalendarName(name) {
        googleCalendarName = name && String(name).trim().length > 0 ? String(name).trim() : "primary";
        saveSettings();
    }

    function setGoogleCalendarSyncNewReminders(enabled) {
        googleCalendarSyncNewReminders = enabled;
        saveSettings();
    }

    function parseIndex() {
        try {
            const raw = indexFile.text();
            if (!raw || raw.trim().length === "")
                return {
                    order: [],
                    notes: {}
                };
            const data = JSON.parse(raw);
            return {
                order: data.order || [],
                notes: data.notes || {}
            };
        } catch (e) {
            return {
                order: [],
                notes: {}
            };
        }
    }

    function loadIndex() {
        if (!persistentStorage) {
            reminders = [];
            dueReminders = [];
            unseenCount = 0;
            return;
        }

        const now = Date.now();
        const data = parseIndex();
        const all = [];
        const due = [];

        for (let i = 0; i < data.order.length; i++) {
            const id = data.order[i];
            const note = data.notes[id];
            if (!note || !note.reminderEnabled || !note.reminderAt)
                continue;

            const reminderTime = Date.parse(note.reminderAt);
            if (isNaN(reminderTime))
                continue;

            const entry = {
                id: id,
                title: note.title || "Untitled Note",
                reminderAt: note.reminderAt,
                reminderSeen: note.reminderSeen === true,
                googleCalendarSynced: note.googleCalendarSynced === true,
                googleCalendarSyncedAt: note.googleCalendarSyncedAt || "",
                due: reminderTime <= now
            };

            all.push(entry);
            if (entry.due)
                due.push(entry);
        }

        const previousUnseen = unseenCount;
        all.sort((a, b) => Date.parse(a.reminderAt) - Date.parse(b.reminderAt));
        reminders = all;
        dueReminders = due;
        unseenCount = due.filter(note => !note.reminderSeen).length;

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

    function escapeHtml(value) {
        return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
    }

    function googleScriptPath() {
        return decodeURIComponent(Qt.resolvedUrl("../../scripts/google_calendar.py").toString().replace("file://", ""));
    }

    function parseGoogleOutput(raw, fallbackMessage) {
        try {
            const text = raw && raw.trim().length > 0 ? raw.trim().split("\n").pop() : "";
            return text.length > 0 ? JSON.parse(text) : {
                ok: false,
                connected: false,
                message: fallbackMessage
            };
        } catch (e) {
            return {
                ok: false,
                connected: false,
                message: fallbackMessage + ": " + e
            };
        }
    }

    function refreshGoogleCalendar() {
        if (!googleCalendarEnabled || googleStatusProcess.running)
            return;
        googleCalendarSyncing = true;
        googleStatusProcess.command = ["python3", googleScriptPath(), "status"];
        googleStatusProcess.running = true;
    }

    function refreshGoogleAgenda() {
        if (!googleCalendarEnabled || googleAgendaProcess.running)
            return;
        googleCalendarSyncing = true;
        googleAgendaProcess.command = ["python3", googleScriptPath(), "agenda", "--start", "now", "--end", "7d"];
        googleAgendaProcess.running = true;
    }

    function connectGoogleCalendar() {
        if (googleConnectProcess.running)
            return;
        googleCalendarStatus = "Opening Google Calendar OAuth flow";
        googleConnectProcess.command = ["python3", googleScriptPath(), "connect"];
        googleConnectProcess.running = true;
    }

    function applyGoogleStatusOutput(raw, exitCode) {
        const data = parseGoogleOutput(raw, "Could not check Google Calendar");
        googleCalendarConnected = data.connected === true;
        googleCalendarStatus = data.message || (googleCalendarConnected ? "Connected" : "Not connected");
        googleCalendarChanged();
        if (googleCalendarConnected)
            refreshGoogleAgenda();
    }

    function applyGoogleAgendaOutput(raw, exitCode) {
        const data = parseGoogleOutput(raw, "Could not load Google Calendar agenda");
        googleCalendarConnected = data.connected === true;
        googleCalendarStatus = data.message || (googleCalendarConnected ? "Agenda loaded" : "Not connected");
        googleCalendarEvents = data.events || [];
        googleCalendarLastSync = new Date().toLocaleString();
        googleCalendarChanged();
    }

    function applyGoogleConnectOutput(raw, exitCode) {
        const data = parseGoogleOutput(raw, "Could not start Google Calendar connection");
        googleCalendarStatus = data.message || "Google Calendar connection requested";
        googleCalendarChanged();
    }

    function applyGooglePushOutput(raw, exitCode, noteId) {
        const data = parseGoogleOutput(raw, "Could not create Google reminder");
        googleCalendarConnected = data.connected === true || googleCalendarConnected;
        googleCalendarLastPushMessage = data.message || "";
        googleCalendarStatus = googleCalendarLastPushMessage;
        if (data.ok === true && noteId)
            markGoogleSynced(noteId);
        googleCalendarChanged();
        if (data.ok === true)
            refreshGoogleAgenda();
    }

    function newNoteId() {
        return "note-" + Date.now() + "-" + Math.random().toString(16).slice(2, 8);
    }

    function createNote(title, htmlContent, reminderAt) {
        if (!fileReady || createNoteProcess.running)
            return "";

        const noteId = newNoteId();
        const now = new Date().toISOString();
        const cleanTitle = title && String(title).trim().length > 0 ? String(title).trim() : "New note";
        const content = htmlContent && String(htmlContent).length > 0 ? String(htmlContent) : "<h1>" + escapeHtml(cleanTitle) + "</h1><p></p>";
        const reminder = reminderAt || "";
        const reminderEnabled = reminder.length > 0 ? "true" : "false";

        createNoteProcess.noteId = noteId;
        createNoteProcess.command = ["bash", "-lc", ["set -euo pipefail", "notes_dir=" + shellQuote(notesDir), "index_path=" + shellQuote(indexPath), "note_id=" + shellQuote(noteId), "title=" + shellQuote(cleanTitle), "created=" + shellQuote(now), "reminder_at=" + shellQuote(reminder), "reminder_enabled=" + shellQuote(reminderEnabled), "mkdir -p \"$notes_dir/notes\"", "printf '%s' " + shellQuote(content) + " > \"$notes_dir/notes/$note_id.html\"", "if [ ! -s \"$index_path\" ]; then printf '%s\\n' '{\"order\":[],\"notes\":{}}' > \"$index_path\"; fi", "tmp=\"$(mktemp)\"", "jq --arg id \"$note_id\" --arg title \"$title\" --arg created \"$created\" --arg reminder \"$reminder_at\" --argjson enabled \"$reminder_enabled\" '", "  .order = ([ $id ] + ((.order // []) | map(select(. != $id)))) |", "  .notes[$id] = {", "    title: $title,", "    created: $created,", "    modified: $created,", "    isMarkdown: false,", "    reminderEnabled: $enabled,", "    reminderAt: $reminder,", "    reminderSeen: false,", "    googleCalendarSynced: false,", "    googleCalendarSyncedAt: \"\"", "  }", "' \"$index_path\" > \"$tmp\"", "mv \"$tmp\" \"$index_path\""].join("\n")];
        createNoteProcess.running = true;
        return noteId;
    }

    function createQuickNote() {
        const title = "New note " + new Date().toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit"
        });
        return createNote(title, "", "");
    }

    function createQuickReminder() {
        const reminderAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
        const title = "New reminder";
        const content = "<h1>" + escapeHtml(title) + "</h1><p>Reminder created from Vibeshell Notes.</p>";
        return createNote(title, content, reminderAt);
    }

    function sendReminderNotification(fromLogin) {
        if (unseenCount <= 0)
            return;

        const unseen = dueReminders.filter(note => !note.reminderSeen);
        const summary = fromLogin ? "Notes waiting from last session" : "Note reminder";
        const body = unseen.length === 1 ? unseen[0].title : unseen.length + " notes need attention";

        notifyProcess.command = ["bash", "-lc", "command -v notify-send >/dev/null && notify-send " + shellQuote(summary) + " " + shellQuote(body) + " || true"];
        notifyProcess.running = true;
    }

    function syncReminderToGoogle(noteId) {
        if (!fileReady || !googleCalendarEnabled || googlePushProcess.running || !noteId)
            return;

        const data = parseIndex();
        const note = data.notes[noteId];
        if (!note || note.reminderEnabled !== true || !note.reminderAt) {
            googleCalendarLastPushMessage = "Selected note has no reminder to sync";
            googleCalendarChanged();
            return;
        }

        googleCalendarSyncing = true;
        googlePushProcess.noteId = noteId;
        googlePushProcess.command = [
            "python3",
            googleScriptPath(),
            "add-reminder",
            "--calendar",
            googleCalendarName || "primary",
            "--title",
            note.title || "Vibeshell reminder",
            "--when",
            note.reminderAt,
            "--description",
            "Created from Vibeshell Notes: " + (note.title || "Untitled Note")
        ];
        googlePushProcess.running = true;
    }

    function syncAllRemindersToGoogle() {
        if (!googleCalendarEnabled || googlePushProcess.running)
            return;

        const data = parseIndex();
        for (let i = 0; i < data.order.length; i++) {
            const id = data.order[i];
            const note = data.notes[id];
            if (note && note.reminderEnabled === true && note.reminderAt && note.googleCalendarSynced !== true) {
                syncReminderToGoogle(id);
                return;
            }
        }

        googleCalendarLastPushMessage = "All local reminders are already synced";
        googleCalendarChanged();
    }

    function markGoogleSynced(noteId) {
        if (!fileReady || !noteId)
            return;

        const data = parseIndex();
        if (data.notes[noteId]) {
            data.notes[noteId].googleCalendarSynced = true;
            data.notes[noteId].googleCalendarSyncedAt = new Date().toISOString();
            indexFile.setText(JSON.stringify(data, null, 2));
            indexFile.reload();
        }
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
            data.notes[noteId].googleCalendarSynced = false;
            data.notes[noteId].googleCalendarSyncedAt = "";
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
