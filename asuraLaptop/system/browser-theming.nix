# Browser Theming and File Manager Fixes
{ pkgs, ... }:

{
  # Environment variables for browser theming
  environment.sessionVariables = {
    # Force dark theme for browsers
    GTK_THEME = "Adwaita:dark";

    # Firefox/Zen browser dark theme
    MOZ_USE_XINPUT2 = "1";

    # Chromium-based browsers dark theme
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  };

  # System-wide browser theming
  environment.etc = {
    # Firefox/Zen browser user.js for dark theme
    "firefox/user.js".text = ''
      // Force dark theme
      user_pref("ui.systemUsesDarkTheme", 1);
      user_pref("browser.theme.content-theme", 0);
      user_pref("browser.theme.toolbar-theme", 0);
      user_pref("devtools.theme", "dark");

      // Dark scrollbars
      user_pref("widget.content.allow-gtk-dark-theme", true);

      // Prefer dark color scheme
      user_pref("layout.css.prefers-color-scheme.content-override", 0);
    '';
  };

  # Fix Nemo thumbnail cache permissions
  systemd.tmpfiles.rules = [
    # Create thumbnail cache directories with proper permissions
    "d /home/asura/.cache 0755 asura users -"
    "d /home/asura/.cache/thumbnails 0755 asura users -"
    "d /home/asura/.cache/thumbnails/normal 0755 asura users -"
    "d /home/asura/.cache/thumbnails/large 0755 asura users -"
    "d /home/asura/.cache/thumbnails/fail 0755 asura users -"

    # Nemo specific cache directories
    "d /home/asura/.cache/nemo 0755 asura users -"
    "d /home/asura/.local/share/nemo 0755 asura users -"

    # Ensure ownership/permissions are correct even if root created them
    "Z /home/asura/.cache/thumbnails 0755 asura users - -"
    "Z /home/asura/.cache/nemo 0755 asura users - -"
    "Z /home/asura/.local/share/nemo 0755 asura users - -"
  ];

  # Additional packages for thumbnail generation
  environment.systemPackages = with pkgs; [
    # Thumbnail generators
    ffmpegthumbnailer  # Video thumbnails
    poppler-utils      # PDF thumbnails
    libgsf             # Office document thumbnails

    # MIME type support
    shared-mime-info
    desktop-file-utils
  ];

  # Services for thumbnail generation
  services.tumbler.enable = true;  # Thumbnail service
}
