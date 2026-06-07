pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string notesPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/vibeshell/notes.json"
    property var notes: []
    property bool ready: false
    property string error: ""

    Process {
        id: loadProcess
        running: false
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim().length > 0 ? text.trim() : "[]");
                    root.notes = Array.isArray(parsed) ? parsed : [];
                    root.error = "";
                } catch (e) {
                    root.notes = [];
                    root.error = "Could not load notes";
                }
                root.ready = true;
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.notes = [];
                root.ready = true;
                root.error = "Could not load notes";
            }
        }
    }

    Process {
        id: saveProcess
        running: false
        command: []
        onExited: code => {
            root.error = code === 0 ? "" : "Could not save notes";
        }
    }

    function load() {
        loadProcess.command = ["python3", "-c", `
import json, os, shutil, sys, time
path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
if not os.path.exists(path):
    print("[]")
    raise SystemExit(0)
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, list):
        raise ValueError("notes root must be a list")
except Exception:
    backup = f"{path}.broken-{int(time.time())}"
    try:
        shutil.copy2(path, backup)
    except Exception:
        pass
    print("[]")
else:
    print(json.dumps(data))
`, notesPath];
        loadProcess.running = true;
    }

    function save() {
        saveProcess.command = ["python3", "-c", `
import json, os, sys, tempfile
path = sys.argv[1]
data = json.loads(sys.argv[2])
os.makedirs(os.path.dirname(path), exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".notes.", dir=os.path.dirname(path), text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\\n")
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)
except Exception:
    try:
        os.unlink(tmp)
    except FileNotFoundError:
        pass
    raise
`, notesPath, JSON.stringify(notes)];
        saveProcess.running = true;
    }

    function normalizeText(text) {
        return String(text || "").trim();
    }

    function createNote(text) {
        const clean = normalizeText(text);
        if (clean.length === 0)
            return;
        const now = new Date().toISOString();
        const next = notes.slice();
        next.unshift({
            id: now + "-" + Math.floor(Math.random() * 100000),
            text: clean,
            createdAt: now,
            updatedAt: now
        });
        notes = next;
        save();
    }

    function updateNote(id, text) {
        const clean = normalizeText(text);
        const next = notes.slice();
        for (let i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                if (clean.length === 0) {
                    next.splice(i, 1);
                } else {
                    const note = Object.assign({}, next[i]);
                    note.text = clean;
                    note.updatedAt = new Date().toISOString();
                    next[i] = note;
                }
                notes = next;
                save();
                return;
            }
        }
    }

    function deleteNote(id) {
        notes = notes.filter(note => note.id !== id);
        save();
    }

    Component.onCompleted: load()
}
