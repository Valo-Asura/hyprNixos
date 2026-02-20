# Ambxst Home Manager integration
{ ... }:

{
  xdg.configFile."Ambxst/binds.json".source = ./binds.json;
  xdg.configFile."Ambxst/config/system.json".source = ./system.json;

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
