# Browser Configuration and Theming
{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    # Keep the pre-26.05 profile path explicit for this existing install.
    configPath = ".mozilla/firefox";

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
    commandLineArgs = [ ];
  };

  xdg.mimeApps = {
    defaultApplications = {
      "application/xhtml+xml" = "google-chrome.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
    };
    associations.added = {
      "application/xhtml+xml" = "google-chrome.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
    };
  };

  home.packages = [
    pkgs.google-chrome
  ];
}
