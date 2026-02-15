# Browser Configuration and Theming
{ pkgs, ... }:

{
  # Firefox/Zen browser configuration
  programs.firefox = {
    enable = true;

    profiles.default = {
      settings = {
        # Force dark theme
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "devtools.theme" = "dark";

        # Dark scrollbars and content
        "widget.content.allow-gtk-dark-theme" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;

        # Additional dark theme preferences
        "browser.display.use_system_colors" = true;
        "browser.anchor_color" = "#0096ff";
        "browser.visited_color" = "#ff00ff";

        # Privacy and performance
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.cache.disk.enable" = true;
      };

      userChrome = ''
        /* Dark theme for Firefox/Zen browser interface */
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

        /* Root colors */
        :root {
          --toolbar-bgcolor: #1d2021 !important;
          --toolbar-color: #ebdbb2 !important;
          --lwt-accent-color: #1d2021 !important;
          --lwt-text-color: #ebdbb2 !important;
        }

        /* Toolbar styling */
        #nav-bar, #PersonalToolbar, #TabsToolbar {
          background-color: #1d2021 !important;
          color: #ebdbb2 !important;
        }

        /* Tab styling */
        .tabbrowser-tab {
          background-color: #282828 !important;
          color: #ebdbb2 !important;
        }

        .tabbrowser-tab[selected="true"] {
          background-color: #3c3836 !important;
          color: #fbf1c7 !important;
        }
      '';

      userContent = ''
        /* Dark theme for web content */
        @-moz-document url-prefix(about:) {
          body {
            background-color: #1d2021 !important;
            color: #ebdbb2 !important;
          }
        }

        /* Force dark scrollbars */
        * {
          scrollbar-color: #504945 #282828 !important;
        }
      '';
    };
  };

  # File manager (Nemo) configuration
  dconf.settings = {
    "org/cinnamon/desktop/default-applications/terminal" = {
      exec = "kitty";
    };

    # Nemo file manager settings
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      thumbnail-limit = 10485760; # 10MB limit for thumbnails
      click-policy = "double";
    };

    # Thumbnail settings
    "org/nemo/preferences/thumbnail" = {
      thumbnail-limit = 10485760;
      show-thumbnails = "always";
    };

    # Fix thumbnail cache permissions
    "org/gnome/desktop/thumbnailers" = {
      disable-all = false;
    };
  };

  # Additional browser packages
  home.packages = with pkgs; [
    # Browser support
    firefox

    # Thumbnail support
    ffmpegthumbnailer
    imagemagick
    poppler-utils
  ];
}
