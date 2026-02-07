# OpenClaw Gateway (declarative config + user service)
{ inputs, pkgs, ... }:

let
  openclawPkgs = pkgs.callPackage "${inputs.nix-openclaw}/nix/packages" { };
  openclawPkg = openclawPkgs.openclaw;
  openclawGateway = pkgs.writeShellScriptBin "openclaw-gateway" ''
    set -euo pipefail

    if [ -r /run/secrets/OPENCLAW_GATEWAY_TOKEN ]; then
      export OPENCLAW_GATEWAY_TOKEN="$(cat /run/secrets/OPENCLAW_GATEWAY_TOKEN)"
    fi

    exec ${openclawPkg}/bin/openclaw gateway
  '';
in {
  home.packages = [
    openclawPkg
    openclawGateway
  ];

  # OpenClaw config (OpenAI chat completions enabled)
  home.file.".openclaw/openclaw.json".text = ''
    {
      "gateway": {
        "mode": "local",
        "port": 18789,
        "auth": {
          "mode": "token"
        },
        "http": {
          "endpoints": {
            "chatCompletions": {
              "enabled": true
            }
          }
        }
      }
    }
  '';

  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "OpenClaw Gateway";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${openclawGateway}/bin/openclaw-gateway";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
