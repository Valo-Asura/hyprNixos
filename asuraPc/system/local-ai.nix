# Local AI stack
{
  pkgs,
  pkgsOllama,
  lib,
  ...
}:

let
  ollamaPkg = pkgsOllama.ollama-vulkan;

  aiLocalStart = pkgs.writeShellScriptBin "ai-local-start" ''
    set -euo pipefail
    ${pkgs.systemd}/bin/systemctl --user start ollama-local.service

    for _ in $(seq 1 40); do
      if ${pkgs.curl}/bin/curl -fsS --max-time 1 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "ollama-local.service is ready."
        exit 0
      fi
      sleep 0.25
    done

    echo "Timed out waiting for ollama-local.service" >&2
    exit 1
  '';

  aiLocalStop = pkgs.writeShellScriptBin "ai-local-stop" ''
    set -euo pipefail
    ${pkgs.systemd}/bin/systemctl --user stop ollama-local.service
    echo "Stopped ollama-local.service."
  '';

  aiLocalStatus = pkgs.writeShellScriptBin "ai-local-status" ''
    set -euo pipefail
    state="$(${pkgs.systemd}/bin/systemctl --user is-active ollama-local.service 2>/dev/null || true)"
    echo "ollama-local.service: ''${state:-inactive}"
    if [ "$state" = "active" ]; then
      ${pkgs.curl}/bin/curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags || true
    fi
  '';

  aiModelPull = pkgs.writeShellScriptBin "ai-model-pull" ''
    set -euo pipefail
    model="''${1:-qwen3:1.7b}"
    ${aiLocalStart}/bin/ai-local-start >/dev/null
    exec ${ollamaPkg}/bin/ollama pull "$model"
  '';

  aiModelsPullCore = pkgs.writeShellScriptBin "ai-models-pull-core" ''
    set -euo pipefail
    ${aiLocalStart}/bin/ai-local-start >/dev/null
    ${ollamaPkg}/bin/ollama pull qwen3:1.7b
    ${ollamaPkg}/bin/ollama pull gemma4:e2b
  '';

  aiDownloadStop = pkgs.writeShellScriptBin "ai-download-stop" ''
    set -euo pipefail
    ${pkgs.procps}/bin/pkill -f 'ollama pull' >/dev/null 2>&1 || true
    ${pkgs.systemd}/bin/systemctl --user stop ollama-local.service >/dev/null 2>&1 || true
    echo "Stopped Ollama downloads and local service."
  '';
in

{
  environment.systemPackages = [
    ollamaPkg
    aiLocalStart
    aiLocalStop
    aiLocalStatus
    aiModelPull
    aiModelsPullCore
    aiDownloadStop
  ];

  services.ollama = {
    enable = lib.mkForce false;
    loadModels = lib.mkForce [ ];
  };

  systemd.services.ollama-model-loader.enable = lib.mkForce false;

  systemd.user.services.ollama-local = {
    description = "On-demand local Ollama API for Vibeshell";
    after = [ "graphical-session.target" ];
    path = [
      ollamaPkg
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.gnugrep
    ];
    serviceConfig = {
      ExecStart = "${ollamaPkg}/bin/ollama serve";
      Restart = "on-failure";
      RestartSec = 2;
      WorkingDirectory = "%h";
      Environment = [
        "HOME=%h"
        "XDG_DATA_HOME=%h/.local/share"
        "OLLAMA_HOST=127.0.0.1:11434"
        "OLLAMA_MODELS=%h/.local/share/ollama/models"
        "OLLAMA_KEEP_ALIVE=2m"
        "OLLAMA_MAX_LOADED_MODELS=1"
        "OLLAMA_NUM_PARALLEL=1"
        "OLLAMA_GPU_OVERHEAD=0"
        "OLLAMA_MAX_VRAM=8000000000"
      ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      MemoryDenyWriteExecute = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
