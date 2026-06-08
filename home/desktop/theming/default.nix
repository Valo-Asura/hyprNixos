# Theming configuration
# Stylix owns the base theme. We add a few desktop-specific keys on top.
{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 18;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.sessionVariables = {
    GTK_THEME = "adw-gtk3-dark";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  dconf.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 18;
    };

    "org/gtk/settings/file-chooser" = {
      show-hidden = true;
    };

    "org/gnome/nautilus/preferences" = {
      show-hidden-files = true;
    };

    "org.cinnamon.desktop.interface" = {
      gtk-theme = "Stylix";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 18;
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  home.file.".config/gtk-3.0/gtk.css".force = true;
  home.file.".config/gtk-4.0/gtk.css".force = true;
  home.file.".config/gtk-4.0/gtk-dark.css".force = true;

  xdg.configFile."qt5ct/qt5ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/vibeshell.colors
      custom_palette=true
      icon_theme=Papirus-Dark
      standard_dialogs=default
      style=Fusion

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=0
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [SettingsWindow]
      geometry=@ByteArray()
    '';
  };

  xdg.configFile."qt6ct/qt6ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/vibeshell.colors
      custom_palette=true
      icon_theme=Papirus-Dark
      standard_dialogs=default
      style=Fusion

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=0
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [SettingsWindow]
      geometry=@ByteArray()
    '';
  };
}
