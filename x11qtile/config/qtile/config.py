# config.py
# Main configuration file for Qtile under X11
import os
import subprocess
from libqtile import bar, hook, layout, qtile
from libqtile.config import Screen, Group, Key, Match, Drag, Click
from libqtile.lazy import lazy

# Import modular configurations
from keybindings import keys, mouse
from theme import lay_config, font
from widgets import init_widgets

# Groups definition (Workspaces 1 to 9 matching Hyprland)
groups = [Group(f"{i + 1}", label="") for i in range(9)]

# Bind keys to group actions
for i in groups:
    keys.extend([
        Key(["mod4"], i.name, lazy.group[i.name].toscreen(),
            desc=f"Switch to group {i.name}"),
        Key(["mod4", "shift"], i.name, lazy.window.togroup(i.name, switch_group=True),
            desc=f"Switch to and move focused window to group {i.name}"),
    ])

# Layouts definition
layouts = [
    layout.Bsp(**lay_config, fair=False, border_on_single=True),
    layout.Columns(**lay_config, border_on_single=True, num_columns=2, split=False),
    layout.Floating(**lay_config),
    layout.Max(**lay_config),
]

# Default widget settings
widget_defaults = dict(
    font=font,
    fontsize=12,
    padding=3,
)
extension_defaults = [widget_defaults.copy()]

# Screens setup (single monitor bar mirroring Cozytile)
screens = [
    Screen(
        top=bar.Bar(
            init_widgets(),
            30,
            border_color="#282738",
            border_width=[0, 0, 0, 0],
            margin=[15, 60, 6, 60],
        ),
    ),
]

# Startup hook
@hook.subscribe.startup_once
def autostart():
    config_dir = os.environ.get("X11QTILE_CONFIG_DIR", os.path.dirname(__file__))
    autostart_path = os.path.join(config_dir, "autostart.sh")
    if os.path.isfile(autostart_path) and os.access(autostart_path, os.X_OK):
        env = os.environ.copy()
        env["X11QTILE_CONFIG_DIR"] = config_dir
        subprocess.Popen([autostart_path], env=env)

# Miscellaneous settings
dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    border_focus="#1F1D2E",
    border_normal="#1F1D2E",
    border_width=0,
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ],
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"
