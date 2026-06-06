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

## Memory Integration
You are connected to the unified memory MCP servers:
- `ai-memory-files`: Access to `~/.config/ai-unified-memory/` filesystem.
- `ai-memory-sqlite`: Access to SQLite database `~/.config/ai-unified-memory/memory/history.db`.

### Connected Agent Clients
- Codex reads this `AGENTS.md` and global `~/.codex/AGENTS.md`; MCP servers are configured in `~/.codex/config.toml`.
- Cursor reads `.cursor/rules/global.mdc` and `~/.cursor/rules/ai-unified-memory.mdc`; MCP servers are configured in `.cursor/mcp.json` and `~/.cursor/mcp.json`.
- Kiro reads `~/.kiro/steering/AGENTS.md`; MCP servers are configured in `~/.kiro/settings/mcp.json`.
- Antigravity reads `~/.antigravity/rules/ai-unified-memory.md` and `~/.config/Antigravity/User/AGENTS.md`; MCP servers are configured in Antigravity user MCP files.
- Warp has a shared context file at `~/.warp/ai-unified-memory.md`; MCP support is tool-dependent, so the shared filesystem and SQLite paths are also exported through environment variables.

### Operations:
1. **At Session Start**: Query `ai-memory-sqlite` (`memories` table) or read files via `ai-memory-files` to retrieve context on recent tasks, facts, and lessons.
2. **On Task Completion**: Proactively log new facts, gotchas, or lessons learned:
   - For database entries: Run insert queries via the SQLite MCP server to add a new memory record.
   - For file entries: Update the `facts.json` or `lessons.json` files in `ai-memory-files`.
   - Maintain history records containing `kind`, `source`, `content`, and `tags`.
