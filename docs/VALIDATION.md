# Validation

Checked locally on 2026-05-16.

## Hyprland

- Hyprland version: `0.55.0`
- Active config: [hyprland.lua](/home/asura/.config/hypr/hyprland.lua)
- Lua migration status: working
- Validation command:

```bash
hyprctl reload
hyprctl configerrors
```

- Result: `hyprctl reload` returns `ok`
- Result: `hyprctl configerrors` returns no errors
- Known upstream bug: `hyprland --verify-config` can segfault on Lua configs in `0.55.0`

## Build

```bash
git diff --check
nix build --dry-run --no-link .#nixosConfigurations.nixos.config.system.build.toplevel
nix build --no-link --print-out-paths ./asuraPc/vibeshell
```

- Result: evaluation passes
- Result: dry-run succeeds
- Result: standalone Vibeshell build succeeds

## Lockscreen

- Primary lock path: Quickshell / Vibeshell
- Fallback lock path: `hyprlock`
- Shared image: [lockscreen.png](/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png)

## Local AI

- `services.ollama.enable = false`
- `services.ollama.loadModels = [ ]`
- `ollama-model-loader` is disabled
- Start Ollama only when needed with `ai-local-start`
- Pull local models only when needed with `ai-models-pull-core`
- Check local memory/RAG status with `/memory`

## Editors

- VS Code and Kiro have the OpenAI extension installed
- The broken `chatgpt.cliExecutable=/run/current-system/sw/bin/codex` override was the reason Codex failed
- The Home Manager module now removes that bad override during activation
- Restart the editor after switching so Codex uses the bundled CLI again
