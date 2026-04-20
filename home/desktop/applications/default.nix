# Desktop applications
{ lib, pkgs, ... }:

let
  mkChromeApp = {
    name,
    appId,
    url,
    probeUrl ? null,
  }:
    pkgs.writeShellScriptBin appId ''
      set -euo pipefail

      profile_dir="$HOME/.local/share/webapps/${appId}"
      mkdir -p "$profile_dir"

      ${lib.optionalString (probeUrl != null) ''
        for _ in $(seq 1 20); do
          if ${pkgs.curl}/bin/curl --silent --fail --output /dev/null ${lib.escapeShellArg probeUrl}; then
            break
          fi
          sleep 1
        done
      ''}

      exec ${pkgs.google-chrome}/bin/google-chrome-stable \
        --user-data-dir="$profile_dir" \
        --class=${lib.escapeShellArg appId} \
        --name=${lib.escapeShellArg name} \
        --new-window \
        --app=${lib.escapeShellArg url} \
        --ozone-platform-hint=auto \
        --force-dark-mode \
        --enable-features=WebUIDarkMode \
        "$@"
    '';

  openWebUiApp = mkChromeApp {
    name = "Open WebUI";
    appId = "open-webui-app";
    url = "http://127.0.0.1:8080";
    probeUrl = "http://127.0.0.1:8080";
  };

  manusApp = mkChromeApp {
    name = "Manus";
    appId = "manus-app";
    url = "https://manus.im/app";
  };
in
{
  imports = [
    ../../../asuraPc/wofi/default.nix
    ../../../asuraPc/ambxst/home.nix
    ../../../asuraPc/waybar/default.nix
  ];

  home.packages = [
    pkgs.wofi
    openWebUiApp
    manusApp
  ];

  xdg.desktopEntries = {
    open-webui = {
      name = "Open WebUI";
      comment = "Local Ollama workspace";
      exec = "${openWebUiApp}/bin/open-webui-app";
      icon = "google-chrome";
      terminal = false;
      categories = [
        "Development"
        "Network"
      ];
      startupNotify = true;
    };

    manus = {
      name = "Manus";
      comment = "Manus web app in a dedicated Chrome window";
      exec = "${manusApp}/bin/manus-app";
      icon = "google-chrome";
      terminal = false;
      categories = [
        "Network"
        "Office"
      ];
      startupNotify = true;
    };
  };
}
