{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  memoryRoot = "${homeDir}/.config/ai-unified-memory";
  memoryDb = "${memoryRoot}/memory/history.db";

  agentInstructions = ''
    # Global Agent Instructions

    ## Identity
    User is Vimal / Asura, backend-focused SWE using Python, JavaScript, Django, FastAPI, SQL, MongoDB, Linux/NixOS, Hyprland, local AI, and automation workflows.

    ## Coding Rules
    - Prefer full implementations over fragments.
    - Python: type hints, small functions, clear modules.
    - TypeScript: explicit interfaces/types.
    - Prefer composition over inheritance.
    - Keep functions focused and under ~40 lines where practical.
    - Add security notes for SQLi, XSS, IDOR, auth, and secret risks.

    ## System Rules
    - NixOS/Arch Linux workflows should be reproducible.
    - Prefer declarative config when possible.
    - Do not suggest destructive shell commands without checks.
    - For editor/agent config, prefer pinned packages and env vars.

    ## Output Style
    - Blunt, dense, precise.
    - Use tables and code blocks.
    - No filler.

    ## Unified AI Memory
    All local AI agents should use the same memory root:

    ```text
    ${memoryRoot}
    ```

    Primary stores:
    - Filesystem memory: `${memoryRoot}`
    - SQLite memory: `${memoryDb}`
    - Facts: `${memoryRoot}/memory/facts.json`
    - Lessons: `${memoryRoot}/memory/lessons.json`

    Connected clients:
    - Codex: `~/.codex/AGENTS.md`, `~/.codex/config.toml`
    - Cursor: `~/.cursor/rules/ai-unified-memory.mdc`, `~/.cursor/mcp.json`
    - Kiro: `~/.kiro/steering/AGENTS.md`, `~/.kiro/settings/mcp.json`
    - Antigravity: `~/.antigravity/rules/ai-unified-memory.md`, `~/.config/Antigravity/User/AGENTS.md`
    - Warp: `~/.warp/ai-unified-memory.md`

    At session start, read the shared facts/lessons and query SQLite memories when available.
    On task completion, add durable facts, lessons, and gotchas to the shared store.

    ## Desktop Shell Context
    - Active stable shell: `/etc/nixos/asuraPc/vibeshell` (Quickshell/QML).
    - Native rewrite experiment: `/etc/nixos/asuraPc/vibeshellREzero` (separate project, not active by default).
    - Nandriod is not installed or selectable; `/home/asura/Downloads/test/asura-quickshell-main` is reference-only.
    - Current dashboard focus: compact top-attached dashboard, weather refresh state, Pomodoro notes, Settings/Bar separation, and low-stutter Quickshell behavior.
  '';

  factsSeed = {
    user = {
      name = "Vimal";
      aliases = [ "Asura" ];
      role = "Backend-focused Software Engineer";
      preferences = {
        editor = "Zed / VS Code / Cursor / Kiro / Antigravity";
        terminal = "foot + fish";
        os = "NixOS";
        window_manager = "Hyprland";
        preferred_languages = [
          "Python"
          "JavaScript"
          "SQL"
          "C++"
        ];
      };
    };
  };

  cursorServers = {
    aiMemoryFiles = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        memoryRoot
      ];
    };
    aiMemorySqlite = {
      command = "uvx";
      args = [
        "mcp-server-sqlite"
        "--db-path"
        memoryDb
      ];
    };
  };

  vscodeServers = lib.mapAttrs (
    _: server:
    {
      type = "stdio";
      sandboxEnabled = true;
    }
    // server
  ) cursorServers;

  mcpBase = {
    servers = {
      ai-memory-files = cursorServers.aiMemoryFiles;
      ai-memory-sqlite = cursorServers.aiMemorySqlite;
    };
  };

  manifest = {
    version = 1;
    root = memoryRoot;
    sqlite = memoryDb;
    agents = {
      codex = {
        instructions = "${homeDir}/.codex/AGENTS.md";
        mcp = "${homeDir}/.codex/config.toml";
      };
      cursor = {
        instructions = "${homeDir}/.cursor/rules/ai-unified-memory.mdc";
        mcp = "${homeDir}/.cursor/mcp.json";
      };
      kiro = {
        instructions = "${homeDir}/.kiro/steering/AGENTS.md";
        mcp = "${homeDir}/.kiro/settings/mcp.json";
      };
      antigravity = {
        instructions = "${homeDir}/.antigravity/rules/ai-unified-memory.md";
        mcp = "${homeDir}/.config/Antigravity/User/mcp.json";
      };
      warp = {
        instructions = "${homeDir}/.warp/ai-unified-memory.md";
        mcp = null;
      };
    };
  };

  syncScript = pkgs.writeText "sync-ai-unified-memory.py" ''
    import json
    import os
    import shutil
    import sqlite3
    from datetime import datetime
    from pathlib import Path

    HOME = Path(os.environ["HOME"])
    ROOT = Path(${builtins.toJSON memoryRoot})
    DB = Path(${builtins.toJSON memoryDb})
    AGENT_INSTRUCTIONS = ${builtins.toJSON agentInstructions}
    FACTS_SEED = json.loads(${builtins.toJSON (builtins.toJSON factsSeed)})
    MCP_BASE = json.loads(${builtins.toJSON (builtins.toJSON mcpBase)})
    CURSOR_SERVERS = json.loads(${builtins.toJSON (builtins.toJSON cursorServers)})
    VSCODE_SERVERS = json.loads(${builtins.toJSON (builtins.toJSON vscodeServers)})
    MANIFEST = json.loads(${builtins.toJSON (builtins.toJSON manifest)})

    def mkdir(path):
        path.mkdir(parents=True, exist_ok=True)

    def backup(path):
        if not path.exists():
            return
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copyfile(path, path.with_suffix(path.suffix + ".bak-" + stamp))

    def load_json(path):
        if not path.exists():
            return {}
        try:
            text = path.read_text(encoding="utf-8").strip()
            return json.loads(text) if text else {}
        except json.JSONDecodeError:
            backup(path)
            return {}

    def write_json(path, data):
        mkdir(path.parent)
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def write_text(path, text):
        mkdir(path.parent)
        path.write_text(text, encoding="utf-8")

    def merge_json_key(path, key, servers):
        data = load_json(path)
        current = data.get(key)
        if not isinstance(current, dict):
            current = {}
        current.update(servers)
        data[key] = current
        write_json(path, data)

    def merge_codex_config(path):
        marker_start = "# BEGIN ai-unified-memory"
        marker_end = "# END ai-unified-memory"
        existing = path.read_text(encoding="utf-8") if path.exists() else ""

        if marker_start in existing and marker_end in existing:
            head = existing.split(marker_start, 1)[0].rstrip()
            tail = existing.split(marker_end, 1)[1].lstrip()
            existing = (head + "\n\n" + tail).strip()

        block = f"""
    {marker_start}

    [mcp_servers.ai-memory-files]
    command = "npx"
    args = ["-y", "@modelcontextprotocol/server-filesystem", "{ROOT}"]
    enabled = true
    default_tools_approval_mode = "prompt"

    [mcp_servers.ai-memory-sqlite]
    command = "uvx"
    args = ["mcp-server-sqlite", "--db-path", "{DB}"]
    enabled = true
    default_tools_approval_mode = "prompt"

    {marker_end}
    """.strip()
        final = (existing + "\n\n" + block + "\n").lstrip()
        mkdir(path.parent)
        path.write_text(final, encoding="utf-8")

    def ensure_sqlite():
        mkdir(DB.parent)
        conn = sqlite3.connect(DB)
        try:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS memories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    kind TEXT NOT NULL,
                    source TEXT NOT NULL,
                    content TEXT NOT NULL,
                    tags TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memories_kind ON memories(kind)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memories_tags ON memories(tags)")
            content = "Unified memory is shared by Codex, Cursor, Kiro, Antigravity, and Warp from ~/.config/ai-unified-memory."
            exists = conn.execute(
                "SELECT 1 FROM memories WHERE kind = ? AND source = ? AND content = ? LIMIT 1",
                ("fact", "nixos-home-manager", content),
            ).fetchone()
            if not exists:
                conn.execute(
                    "INSERT INTO memories (kind, source, content, tags) VALUES (?, ?, ?, ?)",
                    ("fact", "nixos-home-manager", content, "ai-memory,agents,nixos"),
                )
            conn.commit()
        finally:
            conn.close()

    def ensure_base_memory():
        mkdir(ROOT / "memory")
        mkdir(ROOT / "mcp")
        mkdir(ROOT / "rules")
        mkdir(ROOT / "projects")
        write_text(ROOT / "AGENTS.md", AGENT_INSTRUCTIONS)
        write_json(ROOT / "mcp" / "config.base.json", MCP_BASE)
        write_json(ROOT / "agents.json", MANIFEST)

        facts_path = ROOT / "memory" / "facts.json"
        facts = load_json(facts_path)
        if not facts:
            facts = FACTS_SEED
        facts["ai_unified_memory"] = {
            "root": str(ROOT),
            "sqlite": str(DB),
            "agents": sorted(MANIFEST["agents"].keys()),
            "default_terminal": "foot",
        }
        facts["desktop_shell"] = {
            "active": "vibeshell",
            "vibeshell_path": "/etc/nixos/asuraPc/vibeshell",
            "reference_only_shell_path": "/home/asura/Downloads/test/asura-quickshell-main",
            "native_rewrite_path": "/etc/nixos/asuraPc/vibeshellREzero",
            "current_focus": [
                "compact dashboard",
                "weather refresh state",
                "Pomodoro notes",
                "Settings and Bar tab separation",
                "file-manager/browser desktop integration"
            ],
        }
        write_json(facts_path, facts)

        lessons_path = ROOT / "memory" / "lessons.json"
        lessons = load_json(lessons_path)
        if not isinstance(lessons, list):
            lessons = []
        lesson = {
            "topic": "AI Unified Memory",
            "lesson": "Keep facts, lessons, and history shared across Codex, Cursor, Kiro, Antigravity, and Warp.",
            "solution": "Use ~/.config/ai-unified-memory and the configured MCP filesystem/SQLite servers.",
        }
        if lesson not in lessons:
            lessons.append(lesson)
        shell_lesson = {
            "topic": "Desktop Shell Workflow",
            "lesson": "Keep active VibeShell and native rewrite experiments isolated from each other.",
            "solution": "Treat /home/asura/Downloads/test/asura-quickshell-main as read-only reference only, and make active VibeShell edits small and reversible.",
        }
        if shell_lesson not in lessons:
            lessons.append(shell_lesson)
        write_json(lessons_path, lessons)

    def record_shell_update():
        mkdir(DB.parent)
        conn = sqlite3.connect(DB)
        try:
            content = "Desktop shell update: VibeShell remains active; Nandriod is no longer installed or selectable; dashboard work covers weather refresh, Pomodoro notes, Settings/Bar separation, and file/browser desktop integration."
            exists = conn.execute(
                "SELECT 1 FROM memories WHERE kind = ? AND source = ? AND content = ? LIMIT 1",
                ("fact", "nixos-home-manager", content),
            ).fetchone()
            if not exists:
                conn.execute(
                    "INSERT INTO memories (kind, source, content, tags) VALUES (?, ?, ?, ?)",
                    ("fact", "nixos-home-manager", content, "desktop-shell,vibeshell,quickshell,nixos"),
                )
            conn.commit()
        finally:
            conn.close()

    def sync_agents():
        write_text(HOME / ".codex" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_codex_config(HOME / ".codex" / "config.toml")

        write_text(HOME / ".cursor" / "rules" / "ai-unified-memory.mdc", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".cursor" / "mcp.json", "mcpServers", CURSOR_SERVERS)

        write_text(HOME / ".kiro" / "steering" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".kiro" / "settings" / "mcp.json", "mcpServers", CURSOR_SERVERS)

        write_text(HOME / ".antigravity" / "rules" / "ai-unified-memory.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".antigravity" / "mcp.json", "mcpServers", CURSOR_SERVERS)
        write_text(HOME / ".config" / "Antigravity" / "User" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".config" / "Antigravity" / "User" / "mcp.json", "servers", VSCODE_SERVERS)

        merge_json_key(HOME / ".config" / "Code" / "User" / "mcp.json", "servers", VSCODE_SERVERS)
        merge_json_key(HOME / ".config" / "Cursor" / "User" / "mcp.json", "servers", VSCODE_SERVERS)
        merge_json_key(HOME / ".config" / "Kiro" / "User" / "mcp.json", "servers", VSCODE_SERVERS)

        write_text(HOME / ".warp" / "ai-unified-memory.md", AGENT_INSTRUCTIONS)
        write_json(HOME / ".warp-terminal" / "ai-unified-memory.json", MANIFEST)

    ensure_base_memory()
    ensure_sqlite()
    record_shell_update()
    sync_agents()
  '';
in
{
  home.packages = with pkgs; [
    nodejs
    sqlite
    uv
  ];

  home.sessionVariables = {
    AI_UNIFIED_MEMORY_DIR = memoryRoot;
    AI_UNIFIED_MEMORY_DB = memoryDb;
    AI_MEMORY_PROJECT = "/etc/nixos";
  };

  home.activation.syncAiUnifiedMemory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${syncScript}
  '';

  systemd.user.services.ai-unified-memory-sync = {
    Unit.Description = "Sync unified AI memory context";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${syncScript}";
    };
  };

  systemd.user.timers.ai-unified-memory-sync = {
    Unit.Description = "Daily unified AI memory review/update";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "ai-unified-memory-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
