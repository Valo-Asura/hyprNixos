# widgets.py
# Status bar widgets for Cozytile
import os
import subprocess
from libqtile import widget

def get_asset(name):
    return os.path.expanduser(f"~/.config/x11qtile/qtile/Assets/{name}")

def search():
    subprocess.Popen(
        "rofi -show drun -theme " + os.path.expanduser("~/.config/x11qtile/rofi/settings/launcher/cozy.rasi"),
        shell=True,
        start_new_session=True,
    )

def power():
    subprocess.Popen(
        [os.path.expanduser("~/.config/x11qtile/rofi/scripts/power")],
        start_new_session=True,
    )

def init_widgets():
    return [
        widget.Spacer(
            length=15,
            background="#282738",
        ),
        widget.Image(
            filename=get_asset("launch_Icon.png"),
            margin=2,
            background="#282738",
            mouse_callbacks={"Button1": power},
        ),
        widget.Image(
            filename=get_asset("6.png"),
        ),
        widget.GroupBox(
            font="JetBrainsMono Nerd Font",
            fontsize=16,
            borderwidth=3,
            highlight_method="block",
            active="#CAA9E0",
            block_highlight_text_color="#91B1F0",
            highlight_color="#353446",
            inactive="#282738",
            foreground="#4B427E",
            background="#353446",
            this_current_screen_border="#353446",
            this_screen_border="#353446",
            other_current_screen_border="#353446",
            other_screen_border="#353446",
            urgent_border="#353446",
            rounded=True,
            disable_drag=True,
        ),
        widget.Spacer(
            length=8,
            background="#353446",
        ),
        widget.Image(
            filename=get_asset("1.png"),
        ),
        widget.CurrentLayout(
            mode="icon",
            custom_icon_paths=[get_asset("layout")],
            background="#353446",
            scale=0.50,
        ),
        widget.Image(
            filename=get_asset("5.png"),
        ),
        widget.TextBox(
            text=" ",
            font="Font Awesome 6 Free Solid",
            fontsize=13,
            background="#282738",
            foreground="#CAA9E0",
            mouse_callbacks={"Button1": search},
        ),
        widget.TextBox(
            fmt="Search",
            background="#282738",
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
            foreground="#CAA9E0",
            mouse_callbacks={"Button1": search},
        ),
        widget.Image(
            filename=get_asset("4.png"),
        ),
        widget.WindowName(
            background="#353446",
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
            empty_group_string="Desktop",
            max_chars=130,
            foreground="#CAA9E0",
        ),
        widget.Image(
            filename=get_asset("3.png"),
        ),
        widget.Systray(
            background="#282738",
            fontsize=12,
        ),
        widget.TextBox(
            text=" ",
            background="#282738",
        ),
        widget.Image(
            filename=get_asset("6.png"),
            background="#353446",
        ),
        widget.TextBox(
            text="",
            font="Font Awesome 6 Free Solid",
            fontsize=13,
            background="#353446",
            foreground="#CAA9E0",
        ),
        widget.Memory(
            background="#353446",
            format="{MemUsed: .0f}{mm}",
            foreground="#CAA9E0",
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
            update_interval=5,
        ),
        widget.Image(
            filename=get_asset("2.png"),
        ),
        widget.Spacer(
            length=8,
            background="#353446",
        ),
        # On PC we configure Net widget, on Laptop Battery. This is a G5600G Desktop PC.
        # Let's display Net speed like Cozytile suggests for Desktop PC!
        widget.TextBox(
            text=" ",
            font="Font Awesome 6 Free Solid",
            fontsize=13,
            background="#353446",
            foreground="#CAA9E0",
        ),
        widget.Net(
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
            background="#353446",
            foreground="#CAA9E0",
            format=' {up}  {down}',
        ),
        widget.Image(
            filename=get_asset("2.png"),
        ),
        widget.Spacer(
            length=8,
            background="#353446",
        ),
        widget.TextBox(
            text=" ",
            font="Font Awesome 6 Free Solid",
            fontsize=13,
            background="#353446",
            foreground="#CAA9E0",
        ),
        widget.Volume(
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
            background="#353446",
            foreground="#CAA9E0",
            mute_command="pamixer --toggle-mute",
            volume_up_command="pamixer -i 5",
            volume_down_command="pamixer -d 5",
            get_volume_command="pamixer --get-volume-human",
            update_interval=0.2,
            unmute_format="{volume}%",
            mute_format="M",
        ),
        widget.Image(
            filename=get_asset("5.png"),
            background="#353446",
        ),
        widget.TextBox(
            text=" ",
            font="Font Awesome 6 Free Solid",
            fontsize=13,
            background="#282738",
            foreground="#CAA9E0",
        ),
        widget.Clock(
            format="%I:%M %p",
            background="#282738",
            foreground="#CAA9E0",
            font="JetBrainsMono Nerd Font Bold",
            fontsize=13,
        ),
        widget.Spacer(
            length=18,
            background="#282738",
        ),
    ]
