# Validation Notes

Checked on 2026-05-11.

## Build Checks

```bash
git diff --check
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel
nix build --no-link --print-out-paths ./asuraPc/vibeshell
nix flake check --no-build
```

Results:

- `git diff --check`: not available in `/etc/nixos` because this checkout has no `.git` metadata.
- NixOS toplevel eval/build: passed.
- NixOS toplevel build: passed.
- Vibeshell package build: passed.
- Flake check without builds: passed.

## Vibeshell Runtime Checklist

Use this after switching to the new generation:

```bash
pgrep -a quickshell
newest_qs_log="$(ls -td /run/user/1000/quickshell/by-id/* | head -n 1)/log.qslog"
strings "$newest_qs_log" | rg 'Could not load icon|Failed to parse state|GameModeService: Failed|Vibeshell launch already|GeminiException|AuthenticationError'
jq . /home/asura/.local/state/Vibeshell/states.json
```

Expected:

- Quickshell is running.
- No launch-lock, state parse, Gemini auth, or icon-load errors appear in the current log.
- `states.json` parses as valid JSON.
- LiteLLM is not started by default; set `VIBESHELL_ENABLE_LITELLM=1` when the proxy is needed.
- Long-running clipboard, login-lock, sleep-monitor, and system-monitor helpers stay single-instance.

## Hardware and Storage

- CPU: AMD Ryzen 5 5600G, 6 cores / 12 threads, boost enabled.
- GPU: NVIDIA GeForce GTX 1070 8 GB, driver 580.142.
- RAM: 16 GB class system memory.
- Root/Nix store before the Steam build: 108 GB total, 61 GB used, 42 GB available.
- After building and preserving the new toplevel at `/tmp/asura-nixos-toplevel`: 108 GB total, 63 GB used, 40 GB available.
- User-level Nix GC deleted 19,400 dead store paths and freed 1.2 GiB after the first build. A final build-debris GC deleted another 19,092 dead build-time paths and freed 180.7 MiB.
- `nix-store --gc --print-dead` reports 0 remaining dead paths.
- Steam's Counter-Strike 2 page currently lists 85 GB available storage as the Linux minimum, so the hardware is suitable but the current root filesystem is too small for the CS2 game files unless a larger Steam library is used.

## Screenshots

- Power menu UEFI hover text: `screenshots/validation/vibeshell-powermenu-icons-hover-2026-05-10.png`
- Power menu after Quickshell lock/UEFI validation: `screenshots/validation/vibeshell-powermenu-icons-lock-uefi-2026-05-10.png`
- Settings keybind tab: `screenshots/validation/vibeshell-settings-keybinds-2026-05-09.png`

## Notes

- `sudo nixos-rebuild switch --flake /etc/nixos#nixos` still requires an interactive sudo password in this session, so the running system was verified by building and launching the rebuilt Vibeshell package directly.
- Open the keybinding editor with `SUPER+SHIFT+C`, then select `Keybinds`.
