# Browser Configuration and Theming
{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default = {
      settings = {
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "devtools.theme" = "dark";
        "widget.content.allow-gtk-dark-theme" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.display.use_system_colors" = true;
        "browser.anchor_color" = "#0096ff";
        "browser.visited_color" = "#ff00ff";
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.cache.disk.enable" = true;
      };

      userChrome = ''
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

        :root {
          --toolbar-bgcolor: #1d2021 !important;
          --toolbar-color: #ebdbb2 !important;
          --lwt-accent-color: #1d2021 !important;
          --lwt-text-color: #ebdbb2 !important;
        }

        #nav-bar, #PersonalToolbar, #TabsToolbar {
          background-color: #1d2021 !important;
          color: #ebdbb2 !important;
        }

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
        @-moz-document url-prefix(about:) {
          body {
            background-color: #1d2021 !important;
            color: #ebdbb2 !important;
          }
        }

        * {
          scrollbar-color: #504945 #282828 !important;
        }
      '';
    };
  };

  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode,OverlayScrollbar"
      "--ozone-platform-hint=auto"
      "--disk-cache-size=268435456"
    ];
    extensions = [
      # Gruvbox theme to keep Brave visually close to the current Stylix setup.
      "hmalklkailocblgkjpdagjoieifkdfbj"
      # Dark Reader for site-wide dark mode.
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"
    ];
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
  ];
}
