# widgets.py
# Stable, low-memory status bar widgets for the isolated X11 Qtile session.
import os
import shlex
import subprocess
import time
from pathlib import Path

from libqtile import widget
from theme import colors, font

BAR_BG = colors["bar_bg"]
SURFACE = colors["surface"]
BG = colors["bg"]
ACCENT = colors["active"]
MUTED = colors["muted"]
TEXT = colors["text"]
HIGHLIGHT = colors["highlight"]
WARN = "#E8C374"

_NET_SAMPLE = None
_NET_SPEED_CACHE = {"down": "0 B", "up": "0 B", "last_update": 0.0}
_NET_EXCLUDED_PREFIXES = (
    "lo",
    "docker",
    "br-",
    "veth",
    "virbr",
    "waydroid",
    "zt",
    "tailscale",
)


def run_command(command):
    subprocess.Popen(command, shell=True, start_new_session=True)


def search(*_args):
    run_command(
        "rofi -show drun -theme "
        + os.path.expanduser("~/.config/x11qtile/rofi/settings/launcher/cozy.rasi")
    )


def power(*_args):
    run_command(os.path.expanduser("~/.config/x11qtile/rofi/scripts/power"))


def qtile_state_path(name):
    state_home = Path(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")))
    return state_home / "x11qtile" / name


def weather_status():
    try:
        path = qtile_state_path("weather.txt")
        if path.exists():
            return path.read_text(encoding="utf-8").strip()
    except Exception:
        pass
    return "--"


def get_media_status():
    try:
        status = subprocess.check_output(["playerctl", "status"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        if not status:
            return ""

        title = subprocess.check_output(["playerctl", "metadata", "title"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        album = subprocess.check_output(["playerctl", "metadata", "album"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        artist = subprocess.check_output(["playerctl", "metadata", "artist"], stderr=subprocess.DEVNULL).decode("utf-8").strip()

        parts = []
        if title:
            parts.append(title)
        if album:
            parts.append(album)
        if artist:
            parts.append(artist)

        info = " - ".join(parts)
        if len(info) > 60:
            info = info[:57] + "..."

        icon_glyph = "||" if status == "Playing" else "▶"
        return f"{icon_glyph} {info}"
    except Exception:
        return ""


def get_disk_free():
    try:
        out = subprocess.check_output("df -h / | tail -n 1 | awk '{print $4}'", shell=True).decode("utf-8").strip()
        val = out.rstrip("G").rstrip("M")
        unit = out[-1] if out[-1] in ("G", "M", "T") else ""
        return f"{val} {unit}"
    except Exception:
        return "--"


def get_cpu_load():
    try:
        with open("/proc/loadavg", "r") as f:
            load = f.read().split()[0]
        return load
    except Exception:
        return "--"


def get_memory_usage():
    try:
        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
        mem_total = 0
        mem_available = 0
        for line in lines:
            if line.startswith("MemTotal:"):
                mem_total = int(line.split()[1])
            elif line.startswith("MemAvailable:"):
                mem_available = int(line.split()[1])
        mem_used = mem_total - mem_available
        mem_used_gb = mem_used / (1024 * 1024)
        return f"{mem_used_gb:.2f} G"
    except Exception:
        return "--"


def get_uptime():
    try:
        with open("/proc/uptime", "r") as f:
            uptime_seconds = float(f.readline().split()[0])
        hours = int(uptime_seconds // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        if hours > 0:
            return f"{hours}h {minutes}m"
        return f"{minutes}m"
    except Exception:
        return "--"


def _read_network_bytes():
    rx_total = 0
    tx_total = 0

    try:
        lines = Path("/proc/net/dev").read_text(encoding="utf-8").splitlines()[2:]
    except OSError:
        return None

    for line in lines:
        if ":" not in line:
            continue

        iface, data = line.split(":", 1)
        iface = iface.strip()
        if iface.startswith(_NET_EXCLUDED_PREFIXES):
            continue

        fields = data.split()
        if len(fields) < 16:
            continue

        rx_total += int(fields[0])
        tx_total += int(fields[8])

    return rx_total, tx_total


def format_net_rate(bytes_per_second):
    value = max(0, float(bytes_per_second))
    if value >= 1024 * 1024:
        return f"{value / (1024 * 1024):.1f} MB"
    if value >= 1024:
        return f"{value / 1024:.0f} kB"
    return f"{value:.0f} B"


def update_network_speeds():
    global _NET_SAMPLE, _NET_SPEED_CACHE
    now = time.monotonic()
    if now - _NET_SPEED_CACHE["last_update"] < 0.9:
        return

    totals = _read_network_bytes()
    if totals is None:
        return

    if _NET_SAMPLE is None:
        _NET_SAMPLE = (now, *totals)
        return

    last_time, last_rx, last_tx = _NET_SAMPLE
    elapsed = max(now - last_time, 0.1)
    rx_rate = (totals[0] - last_rx) / elapsed
    tx_rate = (totals[1] - last_tx) / elapsed
    _NET_SAMPLE = (now, *totals)

    _NET_SPEED_CACHE["down"] = format_net_rate(rx_rate)
    _NET_SPEED_CACHE["up"] = format_net_rate(tx_rate)
    _NET_SPEED_CACHE["last_update"] = now


def get_down_speed():
    try:
        update_network_speeds()
        return _NET_SPEED_CACHE["down"]
    except Exception:
        return "0 B"


def get_up_speed():
    try:
        update_network_speeds()
        return _NET_SPEED_CACHE["up"]
    except Exception:
        return "0 B"


def icon(text, bg=BAR_BG, fg=ACCENT, size=15, padding=4, callbacks=None):
    return widget.TextBox(
        text=text,
        font=font,
        fontsize=size,
        padding=padding,
        background=bg,
        foreground=fg,
        mouse_callbacks=callbacks or {},
    )


def gap(length=8, bg=BAR_BG):
    return widget.Spacer(length=length, background=bg)


def init_widgets():
    return [
        gap(10),
        icon("", bg=BAR_BG, fg="#89b4fa", size=15, callbacks={"Button1": search}),
        gap(8),
        widget.GroupBox(
            font=font,
            fontsize=16,
            borderwidth=0,
            margin_y=3,
            margin_x=3,
            padding=4,
            highlight_method="text",
            active="#cdd6f4",               # active workspaces (white/grey)
            inactive="#45475a",             # empty workspaces (dark grey)
            foreground="#cdd6f4",
            background=BAR_BG,
            this_current_screen_border="#a6e3a1",  # focused workspace (green)
            this_screen_border="#a6e3a1",
            other_current_screen_border="#45475a",
            other_screen_border="#45475a",
            urgent_border="#f38ba8",
            rounded=False,
            disable_drag=True,
        ),
        gap(10),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_media_status,
            update_interval=2,
        ),
        widget.Spacer(background=BAR_BG),
        icon("󰈸", bg=BAR_BG, fg="#cba6f7", size=15),
        gap(10),
        icon("", bg=BAR_BG, fg="#f5c2e7", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_disk_free,
            update_interval=30,
        ),
        gap(10),
        icon("", bg=BAR_BG, fg="#89b4fa", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_cpu_load,
            update_interval=3,
        ),
        gap(10),
        icon("󰍛", bg=BAR_BG, fg="#f5c2e7", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_memory_usage,
            update_interval=4,
        ),
        gap(10),
        icon("󰇚", bg=BAR_BG, fg="#a6e3a1", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_down_speed,
            update_interval=2,
        ),
        gap(10),
        icon("󰕒", bg=BAR_BG, fg="#f5c2e7", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_up_speed,
            update_interval=2,
        ),
        gap(10),
        icon("", bg=BAR_BG, fg="#89b4fa", size=13),
        widget.Volume(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            mute_command="pamixer --toggle-mute",
            volume_up_command="pamixer -i 5",
            volume_down_command="pamixer -d 5",
            get_volume_command="pamixer --get-volume-human",
            update_interval=0.5,
            unmute_format="{volume}",
            mute_format="muted",
        ),
        gap(10),
        icon("", bg=BAR_BG, fg="#f5c2e7", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=weather_status,
            update_interval=10,
        ),
        gap(10),
        icon("󰔚", bg=BAR_BG, fg="#89b4fa", size=13),
        widget.GenPollText(
            font=font,
            fontsize=12,
            background=BAR_BG,
            foreground="#cdd6f4",
            func=get_uptime,
            update_interval=60,
        ),
        gap(10),
        icon("", bg=BAR_BG, fg="#f5c2e7", size=13),
        widget.Clock(
            format="%d-%m-%y, %I:%M %p",
            background=BAR_BG,
            foreground="#cdd6f4",
            font=font,
            fontsize=12,
        ),
        gap(10),
        icon("󰍃", bg=BAR_BG, fg="#f38ba8", size=15, callbacks={"Button1": power}),
        gap(10),
    ]
