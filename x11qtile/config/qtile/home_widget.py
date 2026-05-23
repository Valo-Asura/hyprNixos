# home_widget.py
# Desktop dashboard for empty Qtile X11 workspaces.
import os
import shutil
import subprocess
import time
from pathlib import Path


WINDOW_NAME = "qtile_home"
IGNORED_CLASSES = {
    "dunst",
    "eww",
    "nm-applet",
    "notification",
    "qtile-home",
}

_is_open = False


def _eww_config_dir(config_dir):
    return Path(config_dir).resolve().parent / "eww"


def _run_eww(config_dir, *args):
    eww = shutil.which("eww")
    if not eww:
        return None

    env = os.environ.copy()
    env["GDK_BACKEND"] = "x11"
    return subprocess.run(
        [eww, "--config", str(_eww_config_dir(config_dir)), *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
        check=False,
    )


def _ensure_daemon(config_dir):
    result = _run_eww(config_dir, "ping")
    if result and result.returncode == 0:
        return True

    eww = shutil.which("eww")
    if not eww:
        return False

    env = os.environ.copy()
    env["GDK_BACKEND"] = "x11"
    subprocess.Popen(
        [eww, "--config", str(_eww_config_dir(config_dir)), "daemon"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
        start_new_session=True,
    )
    for _ in range(10):
        time.sleep(0.1)
        result = _run_eww(config_dir, "ping")
        if result and result.returncode == 0:
            return True
    return False


def _window_classes(window):
    classes = []
    try:
        classes.extend(window.get_wm_class() or [])
    except Exception:
        pass

    try:
        info = window.info()
        value = info.get("wm_class")
        if isinstance(value, list):
            classes.extend(value)
        elif value:
            classes.append(value)
    except Exception:
        pass

    return {str(item).lower() for item in classes if item}


def _has_visible_clients(qtile):
    group = getattr(qtile, "current_group", None)
    if not group:
        return False

    for window in getattr(group, "windows", []):
        if _window_classes(window).intersection(IGNORED_CLASSES):
            continue
        if getattr(window, "name", "") == "Qtile Home":
            continue
        return True
    return False


def sync(qtile, config_dir):
    global _is_open

    if not _ensure_daemon(config_dir):
        return

    should_show = not _has_visible_clients(qtile)
    if should_show and not _is_open:
        result = _run_eww(config_dir, "open", WINDOW_NAME)
        _is_open = bool(result and result.returncode == 0)
    elif not should_show and _is_open:
        result = _run_eww(config_dir, "close", WINDOW_NAME)
        if not result or result.returncode == 0:
            _is_open = False


def close(config_dir):
    global _is_open
    _run_eww(config_dir, "close", WINDOW_NAME)
    _is_open = False
