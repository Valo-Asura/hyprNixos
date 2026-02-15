# Browser Configuration and Theming
{ pkgs, ... }:

{
<<<<<<< HEAD
  programs.firefox = {
    enable = true;
    # Keep the pre-26.05 profile path explicit for this existing install.
    configPath = ".mozilla/firefox";

    profiles.default = {
      settings = {
=======
  # Firefox/Zen browser configuration
  programs.firefox = {
    enable = true;

    profiles.default = {
      settings = {
        # Force dark theme
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "devtools.theme" = "dark";
<<<<<<< HEAD
        "widget.content.allow-gtk-dark-theme" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.display.use_system_colors" = true;
        "browser.anchor_color" = "#0096ff";
        "browser.visited_color" = "#ff00ff";
=======

        # Dark scrollbars and content
        "widget.content.allow-gtk-dark-theme" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;

        # Additional dark theme preferences
        "browser.display.use_system_colors" = true;
        "browser.anchor_color" = "#0096ff";
        "browser.visited_color" = "#ff00ff";

        # Privacy and performance
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.cache.disk.enable" = true;
      };

      userChrome = ''
<<<<<<< HEAD
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

=======
        /* Dark theme for Firefox/Zen browser interface */
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

        /* Root colors */
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        :root {
          --toolbar-bgcolor: #1d2021 !important;
          --toolbar-color: #ebdbb2 !important;
          --lwt-accent-color: #1d2021 !important;
          --lwt-text-color: #ebdbb2 !important;
        }

<<<<<<< HEAD
=======
        /* Toolbar styling */
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        #nav-bar, #PersonalToolbar, #TabsToolbar {
          background-color: #1d2021 !important;
          color: #ebdbb2 !important;
        }

<<<<<<< HEAD
=======
        /* Tab styling */
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
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
<<<<<<< HEAD
=======
        /* Dark theme for web content */
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        @-moz-document url-prefix(about:) {
          body {
            background-color: #1d2021 !important;
            color: #ebdbb2 !important;
          }
        }

<<<<<<< HEAD
=======
        /* Force dark scrollbars */
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
        * {
          scrollbar-color: #504945 #282828 !important;
        }
      '';
    };
  };

<<<<<<< HEAD
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=OverlayScrollbar"
      "--disk-cache-size=536870912"
    ];
    extensions = [ ];
  };

  xdg.mimeApps = {
    defaultApplications = {
      "application/xhtml+xml" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
    };
    associations.added = {
      "application/xhtml+xml" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
    };
  };

  home.packages = [
    pkgs.google-chrome
=======
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
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  ];
}
