# Local AI stack
{
  pkgs,
  pkgsOllama,
  lib,
  ...
}:

let
  # Override ollama-cuda to include Pascal (sm_61 = GTX 1070) in CUDA arch list
  ollamaPkg = pkgsOllama.ollama-cuda.override {
    cudaArches = [
      "61"
      "75"
      "80"
      "86"
      "90"
    ];
  };
in

{
  # Keep the Ollama CLI available in the shell; the service package alone does not
  # put the binary on the user's PATH.
  environment.systemPackages = [
    ollamaPkg
  ];

  services.ollama = {
    enable = true;
    package = ollamaPkg;
    host = "127.0.0.1";
    port = 11434;

    loadModels = [
      "gemma4:e2b"
      "qwen3:4b"
      "qwen3:1.7b"
    ];

    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "15m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_GPU_OVERHEAD = "0";
      OLLAMA_MAX_VRAM = "8000000000";
    };
  };

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  systemd.services.ollama = {
    serviceConfig = {
      # CUDA requires executable memory mapping and real user context
      MemoryDenyWriteExecute = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };

  systemd.services.open-webui = {
    after = [ "ollama.service" ];
    requires = [ "ollama.service" ];
  };
}
