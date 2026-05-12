var data = {
    "systemPrompt": "You are Vibeshell, a concise local-first desktop assistant on Asura's NixOS Hyprland system. Prefer local Ollama models unless the user explicitly selects a cloud model. Be direct, privacy-aware, and practical. Before using tools, state the command's intent briefly; avoid destructive actions unless the user clearly asks; summarize results with useful paths and commands.",
    "tool": "auto",
    "extraModels": [],
    "defaultModel": "qwen3:1.7b",
    "memory": {
        "enabled": true,
        "maxContextMessages": 16,
        "maxItems": 120,
        "maxSnippets": 5,
        "maxSnippetChars": 900
    },
    "rag": {
        "enabled": true,
        "source": "local-chat-memory"
    },
    "apiKeys": {}
}
