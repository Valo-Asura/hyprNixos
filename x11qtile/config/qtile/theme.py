# theme.py
# Styling configurations for the Jabuti-inspired low-memory Qtile session.

colors = {
    "bg": "#1e1e2e",          # Catppuccin Mocha Base
    "surface": "#181825",     # Catppuccin Mocha Mantle
    "bar_bg": "#11111b",      # Catppuccin Mocha Crust (dark bar background)
    "active": "#a6e3a1",      # Catppuccin Green
    "inactive": "#45475a",    # Catppuccin Surface1 (dark grey)
    "highlight": "#89b4fa",   # Catppuccin Blue
    "text": "#cdd6f4",        # Catppuccin Text
    "muted": "#585b70",       # Catppuccin Subtext0
    "border_focus": "#89b4fa",
    "border_normal": "#1e1e2e",
}

lay_config = {
    "border_width": 2,
    "margin": 8,
    "border_focus": colors["border_focus"],
    "border_normal": colors["border_normal"],
    "grow_amount": 18,
}

font = "JetBrainsMono Nerd Font"
