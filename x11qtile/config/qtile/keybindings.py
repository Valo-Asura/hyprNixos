# keybindings.py
# Key and mouse bindings for Qtile
from libqtile.config import Key, KeyChord, Click, Drag
from libqtile.lazy import lazy
import os

mod = "mod4"  # SUPER key
alt = "mod1"
terminal = "kitty"
launcher = "rofi -show drun -theme " + os.path.expanduser("~/.config/x11qtile/rofi/settings/launcher/cozy.rasi")
script_dir = os.path.expanduser("~/.config/x11qtile/qtile/scripts")
lock_command = f"bash {os.path.join(script_dir, 'x11-lock.sh')}"
clipboard_command = f"bash {os.path.join(script_dir, 'x11-clipboard.sh')} toggle"
clipboard_paste_command = f"bash {os.path.join(script_dir, 'x11-clipboard.sh')} paste"
screenshot_command = f"bash {os.path.join(script_dir, 'x11-screenshot.sh')}"


def layout_command(qtile, *names):
    """Run the first resize/move command supported by the active layout."""
    layout = qtile.current_layout
    for name in names:
        command = getattr(layout, name, None)
        if callable(command):
            command()
            qtile.current_group.layout_all()
            return

# Keybindings mapped closely to Hyprland + Cozytile fallback
keys = [
    # Focus movement: arrows and Vim-style keys both work.
    Key([mod], "Left", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "Right", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),

    # Window shuffling
    Key([mod, "control"], "Left", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod, "control"], "Right", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod, "control"], "Down", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "control"], "Up", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Window resizing
    Key([mod, "shift"], "Left", lazy.layout.grow_left(), desc="Grow window left"),
    Key([mod, "shift"], "Right", lazy.layout.grow_right(), desc="Grow window right"),
    Key([mod, "shift"], "Down", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "shift"], "Up", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod, "control"], "h", lazy.function(layout_command, "grow_left", "shrink"), desc="Resize window left"),
    Key([mod, "control"], "l", lazy.function(layout_command, "grow_right", "grow"), desc="Resize window right"),
    Key([mod, "control"], "j", lazy.function(layout_command, "grow_down", "grow"), desc="Resize window down"),
    Key([mod, "control"], "k", lazy.function(layout_command, "grow_up", "shrink"), desc="Resize window up"),
    Key([mod, alt], "Left", lazy.function(layout_command, "grow_left", "shrink"), desc="Resize window left"),
    Key([mod, alt], "Right", lazy.function(layout_command, "grow_right", "grow"), desc="Resize window right"),
    Key([mod, alt], "Down", lazy.function(layout_command, "grow_down", "grow"), desc="Resize window down"),
    Key([mod, alt], "Up", lazy.function(layout_command, "grow_up", "shrink"), desc="Resize window up"),
    KeyChord([mod], "r", [
        Key([], "Left", lazy.function(layout_command, "grow_left", "shrink"), desc="Resize left"),
        Key([], "Right", lazy.function(layout_command, "grow_right", "grow"), desc="Resize right"),
        Key([], "Down", lazy.function(layout_command, "grow_down", "grow"), desc="Resize down"),
        Key([], "Up", lazy.function(layout_command, "grow_up", "shrink"), desc="Resize up"),
        Key([], "h", lazy.function(layout_command, "grow_left", "shrink"), desc="Resize left"),
        Key([], "l", lazy.function(layout_command, "grow_right", "grow"), desc="Resize right"),
        Key([], "j", lazy.function(layout_command, "grow_down", "grow"), desc="Resize down"),
        Key([], "k", lazy.function(layout_command, "grow_up", "shrink"), desc="Resize up"),
        Key([], "n", lazy.layout.normalize(), desc="Reset sizes"),
        Key([], "Escape", lazy.ungrab_chord(), desc="Exit resize mode"),
    ], mode=True, name="resize"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Hyprland-matched window actions
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "g", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod], "s", lazy.layout.toggle_split(), desc="Toggle split"),
    Key([mod, "shift"], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),

    # System actions
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload Qtile config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod, "shift"], "Escape", lazy.spawn(lock_command), desc="Lock screen"),
    Key([], "XF86ScreenSaver", lazy.spawn(lock_command), desc="Lock screen"),

    # Applications (mapped from Hyprland bindings)
    Key([mod], "t", lazy.spawn(terminal), desc="Launch terminal (Kitty)"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal (Kitty alternate)"),
    Key([mod], "b", lazy.spawn("brave"), desc="Launch browser (Brave)"),
    Key([mod], "f", lazy.spawn("thunar"), desc="Launch file manager (Thunar)"),
    Key([mod], "c", lazy.spawn("code"), desc="Launch VSCode"),
    Key([mod], "e", lazy.spawn("telegram-desktop"), desc="Launch Telegram"),
    Key([mod], "a", lazy.spawn(launcher), desc="Launch application menu"),

    # Custom helper utilities from user's system
    Key([], "XF86AudioMute", lazy.spawn("pamixer --toggle-mute"), desc="Toggle audio mute"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5"), desc="Raise volume"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5"), desc="Lower volume"),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set 5%+"), desc="Raise brightness"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-"), desc="Lower brightness"),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Toggle play/pause"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Next track"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="Previous track"),

    # Clipboard
    Key([mod], "v", lazy.spawn(clipboard_command), desc="Show clipboard history"),
    Key([mod, "control"], "v", lazy.spawn(clipboard_paste_command), desc="Paste CopyQ current item"),

    # Screenshots: copy PNG image data so it can paste into browsers, chats and editors.
    Key([], "Print", lazy.spawn(f"{screenshot_command} area-copy"), desc="Area screenshot to clipboard"),
    Key([mod], "Print", lazy.spawn(f"{screenshot_command} menu"), desc="Screenshot options"),
    Key([mod, "shift"], "Print", lazy.spawn(f"{screenshot_command} area-save-copy"), desc="Area screenshot to file and clipboard"),
    Key(["control"], "Print", lazy.spawn(f"{screenshot_command} full-copy"), desc="Fullscreen screenshot to clipboard"),
    Key([mod, "control"], "Print", lazy.spawn(f"{screenshot_command} full-save-copy"), desc="Fullscreen screenshot to file and clipboard"),
]

# Mouse bindings
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]
