# Validation

Checked locally on 2026-05-18. Package source refreshed on 2026-06-03.

## Hyprland

- Hyprland source: `pkgs.hyprland` from the pinned `nixpkgs` input.
- Current evaluated Hyprland version: check with `nix eval --impure --raw '.#nixosConfigurations.nixos.pkgs.hyprland.version'`; on 2026-06-03 it evaluated to `0.55.2`.
- Active config: [hyprland.lua](/home/asura/.config/hypr/hyprland.lua)
- Lua migration status: working
- Validation command:

```bash
hyprctl reload
hyprctl configerrors
```

- Result: `hyprctl reload` returns `ok`
- Result: `hyprctl configerrors` returns no errors
- Known upstream bug: `hyprland --verify-config` can segfault on Lua configs; use the reload/configerrors workflow above.

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
- Editor theme set is intentionally small: `GitHub Theme` plus `Catppuccin Icons for VSCode`

## Vibeshell

- Closed notch opens the dashboard on left click
- Night Light uses `hyprsunset`; right click its button for intensity control
- Empty stopped browser MPRIS sessions are ignored, so stale Chrome players do not stay in the notch
- Video wallpaper restart no longer deadlocks on the `mpvpaper` lock after reloads
