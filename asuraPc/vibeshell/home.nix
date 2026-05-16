# Vibeshell Home Manager integration
{ lib, pkgs, ... }:

{
  home.activation.seedVibeshellMutableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

        install_mutable_config ${./binds.json} "$HOME/.config/Vibeshell/binds.json"
        install_mutable_config ${./system.json} "$HOME/.config/Vibeshell/config/system.json"

        performance_config="$HOME/.config/Vibeshell/config/performance.json"
        mkdir -p "$(dirname "$performance_config")"
        if [ -f "$performance_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '.wavyLine = true | .blurTransition = false | .windowPreview = false' "$performance_config" > "$tmp" \
            && install -m 0644 "$tmp" "$performance_config"
          rm -f "$tmp"
        else
          install -m 0644 ${./config/defaults/performance.js} "$performance_config.js"
          cat > "$performance_config" <<'EOF'
    {
        "blurTransition": false,
        "windowPreview": false,
        "wavyLine": true
    }
    EOF
          rm -f "$performance_config.js"
        fi

        ai_config="$HOME/.config/Vibeshell/config/ai.json"
        mkdir -p "$(dirname "$ai_config")"
        if [ -f "$ai_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            if .defaultModel == "qwen3:4b" or .defaultModel == "qwen3:8b" or (.defaultModel // "") == "" then .defaultModel = "qwen3:1.7b" else . end
            | .memory = (.memory // {})
            | .memory.enabled = (.memory.enabled // true)
            | .memory.maxContextMessages = (.memory.maxContextMessages // 16)
            | .memory.maxItems = (.memory.maxItems // 120)
            | .memory.maxSnippets = (.memory.maxSnippets // 5)
            | .memory.maxSnippetChars = (.memory.maxSnippetChars // 900)
            | .rag = (.rag // {})
            | .rag.enabled = (.rag.enabled // true)
            | .rag.source = "sqlite-chat-memory"
          ' "$ai_config" > "$tmp" \
            && install -m 0644 "$tmp" "$ai_config"
          rm -f "$tmp"
        else
          install -m 0644 ${./ai.json} "$ai_config"
        fi

        lockscreen_config="$HOME/.config/Vibeshell/config/lockscreen.json"
        mkdir -p "$(dirname "$lockscreen_config")"
        if [ -f "$lockscreen_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .position = (.position // "bottom")
            | if ((.imagePath // "") | length) == 0
              then .imagePath = "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
              else .
              end
          ' "$lockscreen_config" > "$tmp" \
            && install -m 0644 "$tmp" "$lockscreen_config"
          rm -f "$tmp"
        else
          cat > "$lockscreen_config" <<'EOF'
    {
        "position": "bottom",
        "imagePath": "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
    }
    EOF
        fi
  '';

  # nanobot-ai — personal AI assistant backed by local Ollama (Qwen3)
  # Install: pip install --user nanobot-ai
  # Usage: nanobot chat "hello" | nanobot --help
  xdg.configFile."nanobot/config.yaml".text = ''
    llm:
      provider: ollama
      model: qwen3:1.7b
      api_base: http://127.0.0.1:11434
      fallback_model: gemma4:e2b
    assistant:
      name: Asura
      personality: helpful, concise, technical
    logging:
      level: warning
  '';
}
