# Ambxst Home Manager integration
{ lib, ... }:

{
  home.activation.seedAmbxstMutableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install_mutable_config() {
      local source="$1"
      local target="$2"
      local resolved=""

      mkdir -p "$(dirname "$target")"

      if [ -L "$target" ]; then
        resolved="$(readlink -f "$target" || true)"
        case "$resolved" in
          /nix/store/*)
            rm -f "$target"
            install -m 0644 "$source" "$target"
            return
            ;;
        esac
      fi

      if [ ! -e "$target" ]; then
        install -m 0644 "$source" "$target"
      fi
    }

    install_mutable_config ${./binds.json} "$HOME/.config/Ambxst/binds.json"
    install_mutable_config ${./system.json} "$HOME/.config/Ambxst/config/system.json"
  '';

  # nanobot-ai — personal AI assistant backed by local Ollama (Qwen3)
  # Install: pip install --user nanobot-ai
  # Usage: nanobot chat "hello" | nanobot --help
  xdg.configFile."nanobot/config.yaml".text = ''
    llm:
      provider: ollama
      model: qwen3:4b
      api_base: http://127.0.0.1:11434
      fallback_model: qwen3:1.7b
    assistant:
      name: Asura
      personality: helpful, concise, technical
    logging:
      level: warning
  '';
}
