# keybindings.py
# Key and mouse bindings for Qtile
from libqtile.config import Key, Click, Drag
from libqtile.lazy import lazy
import os

mod = "mod4"  # SUPER key
terminal = "kitty"
launcher = "rofi -show drun -theme " + os.path.expanduser("~/.config/x11qtile/rofi/settings/launcher/cozy.rasi")
clipboard = "rofi -modi clipboard -show clipboard -theme " + os.path.expanduser("~/.config/x11qtile/rofi/settings/launcher/cozy.rasi")
screenshot_dir = os.path.expanduser("~/Pictures")

# Keybindings mapped closely to Hyprland + Cozytile fallback
keys = [
    # Window navigation, movement, and resize use arrows to avoid clashing with Hyprland-matched app keys.
    Key([mod], "Left", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "Right", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),

    # Window shuffling
    Key([mod, "control"], "Left", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod, "control"], "Right", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod, "control"], "Down", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "control"], "Up", lazy.layout.shuffle_up(), desc="Move window up"),

    # Window resizing
    Key([mod, "shift"], "Left", lazy.layout.grow_left(), desc="Grow window left"),
    Key([mod, "shift"], "Right", lazy.layout.grow_right(), desc="Grow window right"),
    Key([mod, "shift"], "Down", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "shift"], "Up", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Hyprland-matched window actions
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "g", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod], "j", lazy.layout.toggle_split(), desc="Toggle split"),
    Key([mod, "shift"], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),

    # System actions
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload Qtile config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "l", lazy.spawn("/run/current-system/sw/bin/vibeshell-safe-lock"), desc="Lock screen"),
    Key(["control"], "l", lazy.spawn("/run/current-system/sw/bin/vibeshell-safe-lock"), desc="Lock screen"),

    # Applications (mapped from Hyprland bindings)
    Key([mod], "t", lazy.spawn(terminal), desc="Launch terminal (Kitty)"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal (Kitty alternate)"),
    Key([mod], "b", lazy.spawn("brave"), desc="Launch browser (Brave)"),
    Key([mod], "f", lazy.spawn("thunar"), desc="Launch file manager (Thunar)"),
    Key([mod], "i", lazy.spawn("code"), desc="Launch VSCode"),
    Key([mod], "e", lazy.spawn("telegram-desktop"), desc="Launch Telegram"),
    Key([mod], "w", lazy.spawn(launcher), desc="Launch application menu"),

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
    Key([mod], "v", lazy.spawn(clipboard), desc="Show clipboard"),

    # Screenshots (X11 optimized using maim + xclip)
    Key([], "Print", lazy.spawn("maim -s | xclip -selection clipboard -t image/png"), desc="Interactive screenshot to clipboard"),
    Key([mod], "Print", lazy.spawn(f"mkdir -p {screenshot_dir} && maim {screenshot_dir}/screenshot-$(date +%Y%m%d-%H%M%S).png"), desc="Fullscreen screenshot to file"),
    Key([mod, "shift"], "Print", lazy.spawn(f"mkdir -p {screenshot_dir} && maim -s {screenshot_dir}/screenshot-$(date +%Y%m%d-%H%M%S).png"), desc="Interactive screenshot to file"),
]

# Mouse bindings
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]
