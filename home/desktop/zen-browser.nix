# Zen Browser Dark Theme Configuration
{ pkgs, ... }:

{
  # Create Zen browser profile with dark theme
  home.file = {
    # Zen browser user.js for dark theme
    ".zen/profiles/default/user.js".text = ''
      // Force dark theme for Zen browser
      user_pref("ui.systemUsesDarkTheme", 1);
      user_pref("browser.theme.content-theme", 0);
      user_pref("browser.theme.toolbar-theme", 0);
      user_pref("devtools.theme", "dark");

      // Dark scrollbars and content
      user_pref("widget.content.allow-gtk-dark-theme", true);
      user_pref("layout.css.prefers-color-scheme.content-override", 0);

      // Zen-specific dark theme preferences
      user_pref("browser.display.use_system_colors", true);
      user_pref("ui.use_standins_for_native_colors", true);

      // Additional dark theme settings
      user_pref("browser.anchor_color", "#0096ff");
      user_pref("browser.visited_color", "#ff00ff");
      user_pref("browser.display.background_color", "#1d2021");
      user_pref("browser.display.foreground_color", "#ebdbb2");
    '';

    # Zen browser userChrome.css for interface theming
    ".zen/profiles/default/chrome/userChrome.css".text = ''
      /* Zen Browser Dark Theme */
      @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

      /* Root variables for Gruvbox colors */
      :root {
        --toolbar-bgcolor: #1d2021 !important;
        --toolbar-color: #ebdbb2 !important;
        --lwt-accent-color: #1d2021 !important;
        --lwt-text-color: #ebdbb2 !important;
        --arrowpanel-background: #282828 !important;
        --arrowpanel-color: #ebdbb2 !important;
      }

      /* Toolbar styling */
      #nav-bar, #PersonalToolbar, #TabsToolbar, #toolbar-menubar {
        background-color: #1d2021 !important;
        color: #ebdbb2 !important;
        border-color: #3c3836 !important;
      }

      /* Tab styling */
      .tabbrowser-tab {
        background-color: #282828 !important;
        color: #a89984 !important;
      }

      .tabbrowser-tab[selected="true"] {
        background-color: #3c3836 !important;
        color: #fbf1c7 !important;
      }

      .tabbrowser-tab:hover:not([selected="true"]) {
        background-color: #32302f !important;
        color: #ebdbb2 !important;
      }

      /* URL bar styling */
      #urlbar, #searchbar {
        background-color: #282828 !important;
        color: #ebdbb2 !important;
        border-color: #504945 !important;
      }

      /* Sidebar styling */
      #sidebar-box, #sidebar-header {
        background-color: #1d2021 !important;
        color: #ebdbb2 !important;
      }

      /* Context menu styling */
      menupopup, popup {
        background-color: #282828 !important;
        color: #ebdbb2 !important;
        border-color: #504945 !important;
      }

      menuitem:hover {
        background-color: #3c3836 !important;
        color: #fbf1c7 !important;
      }
    '';

    # Zen browser userContent.css for web content theming
    ".zen/profiles/default/chrome/userContent.css".text = ''
      /* Dark theme for web content */
      @-moz-document url-prefix(about:) {
        body, html {
          background-color: #1d2021 !important;
          color: #ebdbb2 !important;
        }

        a, a:visited {
          color: #83a598 !important;
        }

        a:hover {
          color: #8ec07c !important;
        }
      }

      /* Dark scrollbars everywhere */
      * {
        scrollbar-color: #504945 #282828 !important;
        scrollbar-width: thin !important;
      }

      /* Force dark theme for input fields */
      input, textarea, select {
        background-color: #282828 !important;
        color: #ebdbb2 !important;
        border-color: #504945 !important;
      }
    '';
  };

  # Environment variables for Zen browser
  home.sessionVariables = {
    # Force Zen browser to use dark theme
    ZEN_THEME = "dark";
    MOZ_USE_XINPUT2 = "1";
  };
}
