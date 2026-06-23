#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime


def emit(**payload):
    print(json.dumps(payload, ensure_ascii=False))


def run_gcal(args, timeout=25):
    gcalcli = shutil.which("gcalcli")
    if not gcalcli:
        return 127, "", "gcalcli is not installed"

    env = os.environ.copy()
    env.setdefault("GCALCLI_CONFIG", os.path.join(os.path.expanduser("~"), ".config", "gcalcli"))
    proc = subprocess.run(
        [gcalcli, "--nocolor", *args],
        text=True,
        capture_output=True,
        timeout=timeout,
        env=env,
        check=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def has_local_auth_hint():
    home = os.path.expanduser("~")
    candidates = [
        os.path.join(home, ".config", "gcalcli"),
        os.path.join(home, ".local", "share", "gcalcli"),
        os.path.join(home, ".gcalcli_oauth"),
    ]
    for path in candidates:
        if os.path.exists(path):
            return True
    return False


def status(_args):
    if not shutil.which("gcalcli"):
        emit(ok=False, connected=False, message="Install gcalcli to enable Google Calendar sync")
        return 0

    if not has_local_auth_hint():
        emit(ok=True, connected=False, message="Google Calendar is not connected yet")
        return 0

    code, out, err = run_gcal(["list"], timeout=12)
    if code == 0:
        calendars = [line.strip() for line in out.splitlines() if line.strip()]
        emit(ok=True, connected=True, message="Connected", calendars=calendars)
    else:
        emit(ok=False, connected=False, message=err or out or "Google Calendar auth check failed")
    return 0


def parse_agenda_tsv(raw):
    events = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue

        parts = [part.strip() for part in line.split("\t")]
        title = parts[-1] if parts else line
        date = parts[0] if len(parts) > 0 else ""
        start = parts[1] if len(parts) > 1 else ""
        end = parts[2] if len(parts) > 2 else ""
        calendar = parts[3] if len(parts) > 3 else ""
        events.append({
            "date": date,
            "start": start,
            "end": end,
            "calendar": calendar,
            "title": title,
            "raw": line,
        })
    return events


def agenda(args):
    if not has_local_auth_hint():
        emit(ok=True, connected=False, events=[], message="Connect Google Calendar before loading agenda")
        return 0

    code, out, err = run_gcal(["agenda", args.start, args.end, "--tsv", "--military"], timeout=20)
    if code == 0:
        emit(ok=True, connected=True, events=parse_agenda_tsv(out), message="Agenda loaded")
    else:
        emit(ok=False, connected=False, events=[], message=err or out or "Could not load agenda")
    return 0


def connect(_args):
    terminal = shutil.which("foot") or shutil.which("kitty") or shutil.which("alacritty") or shutil.which("xterm")
    script = (
        "printf 'Vibeshell Google Calendar connection\\n\\n'; "
        "gcalcli init; "
        "printf '\\nConnection command finished. Press Enter to close. '; read _"
    )
    if terminal:
        terminal_name = os.path.basename(terminal)
        if terminal_name == "foot":
            command = [terminal, "--title=Vibeshell Google Calendar", "bash", "-lc", script]
        elif terminal_name == "kitty":
            command = [terminal, "--title", "Vibeshell Google Calendar", "bash", "-lc", script]
        elif terminal_name == "alacritty":
            command = [terminal, "--title", "Vibeshell Google Calendar", "-e", "bash", "-lc", script]
        else:
            command = [terminal, "-T", "Vibeshell Google Calendar", "-e", "bash", "-lc", script]
        subprocess.Popen(command)
        emit(ok=True, connected=False, message="Opened Google Calendar OAuth terminal")
    else:
        emit(ok=False, connected=False, message="No terminal found. Run: gcalcli init")
    return 0


def add_reminder(args):
    if not has_local_auth_hint():
        emit(ok=True, connected=False, message="Connect Google Calendar before syncing reminders")
        return 0

    if not args.title or not args.when:
        emit(ok=False, connected=False, message="Missing title or reminder time")
        return 0

    try:
        parsed = datetime.fromisoformat(args.when.replace("Z", "+00:00"))
        when = parsed.strftime("%Y-%m-%d %H:%M")
    except ValueError:
        when = args.when

    command = [
        "add",
        "--calendar", args.calendar,
        "--title", args.title,
        "--when", when,
        "--duration", str(max(1, args.duration)),
        "--description", args.description,
        "--reminder", args.reminder,
        "--noprompt",
    ]
    code, out, err = run_gcal(command, timeout=30)
    if code == 0:
        emit(ok=True, connected=True, message="Google reminder created", output=out)
    else:
        emit(ok=False, connected=False, message=err or out or "Could not create Google reminder")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Vibeshell Google Calendar bridge")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("status")
    sub.add_parser("connect")

    agenda_parser = sub.add_parser("agenda")
    agenda_parser.add_argument("--start", default="now")
    agenda_parser.add_argument("--end", default="7d")

    add_parser = sub.add_parser("add-reminder")
    add_parser.add_argument("--calendar", default="primary")
    add_parser.add_argument("--title", required=True)
    add_parser.add_argument("--when", required=True)
    add_parser.add_argument("--duration", type=int, default=30)
    add_parser.add_argument("--reminder", default="10m")
    add_parser.add_argument("--description", default="Created by Vibeshell Notes")

    args = parser.parse_args()
    return globals()[args.command.replace("-", "_")](args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.TimeoutExpired:
        emit(ok=False, connected=False, message="Google Calendar command timed out")
        raise SystemExit(0)
    except Exception as exc:
        emit(ok=False, connected=False, message=str(exc))
        raise SystemExit(0)
