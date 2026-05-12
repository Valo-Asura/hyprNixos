# Local AI stack
{
  pkgs,
  pkgsOllama,
  lib,
  ...
}:

let
  # Use Vulkan for GPU acceleration without the CUDA redist fetches that make
  # rebuilds depend on large NVIDIA source downloads.
  ollamaPkg = pkgsOllama.ollama-vulkan;
  pullModel = ''
    ${pkgs.coreutils}/bin/nice -n 15 ${pkgs.util-linux}/bin/ionice -c 3 ${ollamaPkg}/bin/ollama pull "$model"
  '';
  aiModelPull = pkgs.writeShellScriptBin "ai-model-pull" ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      echo "Usage: ai-model-pull <model> [model ...]"
      echo "Example: ai-model-pull qwen3:1.7b nomic-embed-text"
      exit 2
    fi

    export OLLAMA_HOST="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
    for model in "$@"; do
      echo "Pulling $model..."
      ${pullModel}
    done
  '';
  aiModelsPullCore = pkgs.writeShellScriptBin "ai-models-pull-core" ''
    set -euo pipefail

    export OLLAMA_HOST="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
    for model in qwen3:1.7b nomic-embed-text; do
      echo "Pulling $model..."
      ${pullModel}
    done
  '';
  aiDownloadStop = pkgs.writeShellScriptBin "ai-download-stop" ''
    set -euo pipefail

    ${pkgs.systemd}/bin/systemctl stop ollama-model-loader.service >/dev/null 2>&1 || true
    ${pkgs.procps}/bin/pkill -f 'ollama pull' >/dev/null 2>&1 || true
    echo "Stopped Ollama model download jobs."
  '';
  openWebuiPkg = pkgs.open-webui.overridePythonAttrs (oldAttrs: {
    dependencies =
      (oldAttrs.dependencies or [ ])
      ++ (with pkgs.python3Packages; [
        qdrant-client
      ]);
  });
in

{
  # Keep the Ollama CLI available in the shell; the service package alone does not
  # put the binary on the user's PATH.
  environment.systemPackages = [
    ollamaPkg
    aiModelPull
    aiModelsPullCore
    aiDownloadStop
  ];

  services.ollama = {
    enable = true;
    package = ollamaPkg;
    host = "127.0.0.1";
    port = 11434;

    # Do not auto-download multi-GB models during boot. Use `ai-models-pull-core`
    # or `/pull core` in Vibeshell when you actually want to fetch them.
    loadModels = lib.mkForce [ ];

    environmentVariables = {
      # Ollama's default is 5m. Keep local models resident for only 3m so
      # GTX 1070 VRAM is freed quickly after chat activity stops.
      OLLAMA_KEEP_ALIVE = "3m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_GPU_OVERHEAD = "0";
      OLLAMA_MAX_VRAM = "8000000000";
    };
  };

  services.open-webui = {
    enable = true;
    package = openWebuiPkg;
    host = "127.0.0.1";
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      DEFAULT_MODELS = "qwen3:1.7b";
      TASK_MODEL = "qwen3:1.7b";
      ENABLE_MEMORIES = "True";
      VECTOR_DB = "qdrant";
      QDRANT_URI = "http://127.0.0.1:6333";
      QDRANT_ON_DISK = "true";
      QDRANT_TIMEOUT = "10";
      QDRANT_COLLECTION_PREFIX = "open-webui";
      RAG_EMBEDDING_ENGINE = "ollama";
      RAG_OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      RAG_EMBEDDING_MODEL = "nomic-embed-text";
      RAG_EMBEDDING_BATCH_SIZE = "1";
      RAG_EMBEDDING_CONCURRENT_REQUESTS = "1";
      RAG_EMBEDDING_TIMEOUT = "60";
      ENABLE_ASYNC_EMBEDDING = "True";
      ENABLE_RETRIEVAL_QUERY_GENERATION = "True";
      ENABLE_RAG_HYBRID_SEARCH = "True";
      RAG_TOP_K = "4";
      WEBUI_AUTH = "False";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  services.qdrant = {
    enable = true;
    settings = {
      service = {
        host = "127.0.0.1";
        http_port = 6333;
        grpc_port = 6334;
      };
      storage = {
        on_disk_payload = true;
        hnsw_index.on_disk = true;
      };
      telemetry_disabled = true;
    };
  };

  systemd.services.ollama = {
    serviceConfig = {
      # Keep Ollama compatible with its native runtime and model storage.
      MemoryDenyWriteExecute = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };

  systemd.services.ollama-model-loader.enable = lib.mkForce false;

  systemd.services.open-webui = {
    after = [
      "ollama.service"
      "qdrant.service"
    ];
    requires = [
      "ollama.service"
      "qdrant.service"
    ];
    path = [
      pkgs.ffmpeg-headless
    ];
  };

  systemd.services.qdrant = {
    serviceConfig.WorkingDirectory = "/var/lib/qdrant";
  };
}
