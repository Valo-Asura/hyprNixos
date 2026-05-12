# Chromium Browser Theming and Thumbnail Support
{ pkgs, ... }:

{
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    MOZ_USE_XINPUT2 = "1";
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };

  systemd.tmpfiles.rules = [
    "d /home/asura/.cache 0755 asura users -"
    "d /home/asura/.cache/thumbnails 0755 asura users -"
    "d /home/asura/.cache/thumbnails/normal 0755 asura users -"
    "d /home/asura/.cache/thumbnails/large 0755 asura users -"
    "d /home/asura/.cache/thumbnails/fail 0755 asura users -"
    "Z /home/asura/.cache/thumbnails 0755 asura users - -"
  ];

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
    poppler-utils
    libgsf
    shared-mime-info
    desktop-file-utils
  ];

  services.tumbler.enable = true;
}
