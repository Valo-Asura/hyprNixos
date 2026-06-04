# Shell Performance Record

Date: 2026-06-03

This records the baseline before switching from Noctalia + skwd-wall back to
Vibeshell.

## Current Noctalia Baseline

Measured from `systemctl --user status noctalia.service` after about 12 minutes
of uptime.

| Component | State | Memory | CPU |
| --- | --- | ---: | ---: |
| `noctalia.service` | active | 131.6 MB current, 151.7 MB peak | 5.081s over 12 min |
| `noctalia` process | active | 147304 KB RSS | 0.6% sampled |

Observed active Noctalia features from logs/config:

- Shell/bar process active on `DP-1`.
- Top bar enabled with `thickness=34`, `reserve_space=true`, `exclusive_zone=34`.
- Dock enabled on `DP-1`, bottom position, `icon_size=32`.
- Clipboard service bound through `ext_data_control_manager_v1`.
- Gamma/night color service active, applying 6500K day profile.
- IPC socket active at `/run/user/1000/noctalia-wayland-1.sock`.
- Telemetry disabled.
- Wallpaper layer disabled in config.
- Backdrop layer disabled in config.
- Declarative theme set to builtin `Catppuccin`.
- Lock wrapper available as `noctalia-safe-lock`.

## Current skwd-wall Baseline

Measured from `systemctl --user status skwd-daemon.service` after about 12
minutes of uptime.

| Component | State | Memory | CPU |
| --- | --- | ---: | ---: |
| `skwd-daemon.service` cgroup | active | 421 MB current, 422.8 MB peak | 2m35s over 12 min |
| `skwd-daemon` process | active | 26556 KB RSS | 0.0% sampled |
| `quickshell` host | active | 119424 KB RSS | 0.0% sampled |
| `skwd-paper` renderer | active | 226492 KB RSS | 21.3% sampled |

The high memory/CPU came from the persistent live wallpaper renderer, not the
daemon itself. The daemon auto-restored:

```text
/home/asura/Pictures/wallpaper/crimson-blind-faith.1920x1080.mp4
```

The active renderer command included `skwd-paper --persist ... crimson-blind-faith.1920x1080.mp4`.

## Vibeshell Expectations Before A/B Test

Vibeshell is a larger Quickshell/QML shell with dashboards, wallpaper tools,
lock/screenshot helpers, notes, AI config, and system widgets. It is expected to
use more memory than minimal Noctalia, but should avoid the current skwd-wall
video-renderer overhead if MP4 wallpapers are not left running.

The Home Manager Vibeshell seed already applies these lower-cost defaults:

- `wavyLine = false`
- `blurTransition = false`
- `windowPreview = false`
- default AI model lowered to `qwen3:1.7b` when unset or heavier defaults are detected
- lockscreen image set to a static local lock image when unset

## First Comparison Target

After switching to Vibeshell, measure:

```bash
systemctl --user status noctalia.service skwd-daemon.service
ps -eo pid,ppid,comm,rss,vsz,pcpu,pmem,args --sort=-rss | rg -i "vibeshell|quickshell|qs|mpvpaper|noctalia|skwd"
```

Target for the optimized Vibeshell pass:

- No running `noctalia`.
- No running `skwd-daemon`, `skwd-paper`, or skwd-wall `quickshell` host.
- No persistent `mpvpaper` unless explicitly testing animated wallpaper.
- Vibeshell shell memory and CPU recorded under the same conditions as above.

## Vibeshell Optimization Pass

Date: 2026-06-04

Measured from the live session before applying the rebuilt generation. The live
process was still the old Nix store VibeShell, so rebuilt-shell RSS is not yet
claimed here.

### Before Cleanup

Command:

```bash
ps -eo pid,comm,rss,%cpu,args --sort=-rss | sed -n '1,35p'
```

| Component | RSS | CPU | Notes |
| --- | ---: | ---: | --- |
| `mpvpaper` wrapper | 756832 KiB | 3.4% | Playing `/home/asura/Pictures/wallpaper/crimson-blind-faith.1920x1080.mp4`. This was the largest shell-side memory cost. |
| `quickshell` VibeShell | 615292 KiB | 5.3% | Old generation still active from `/nix/store/...-vibeshell-shell-0.1.0/shell.qml`. |
| `ollama-local.service` | running | n/a | User service active from old generation; removed from new system imports. |

### Runtime Cleanup Applied

Commands applied to the current session:

```bash
jq '.currentWall = "/etc/nixos/asuraPc/assets/sans.png" | .wallPath = "/etc/nixos/asuraPc/assets"' \
  ~/.local/share/Vibeshell/wallpapers.json
pkill -f '/bin/mpvpaper( |$)'
systemctl --user stop ollama-local.service
systemctl --user disable ollama-local.service
```

After cleanup:

| Component | Status | Notes |
| --- | --- | --- |
| `mpvpaper` | not running | Static wallpaper state now points to `/etc/nixos/asuraPc/assets/sans.png`. |
| `ollama-local.service` | not running | Stopped and disabled for this user session; new system generation also removes the import. |
| `quickshell` VibeShell | 615932 KiB, 5.3% | Still old generation until `nixos-rebuild switch` and VibeShell restart. |

### Code Changes In This Pass

- Removed VibeShell AI assistant UI, AI config defaults, AI preset files, AI
  service strategy files, `litellm` packaging, AI secret exports, and the
  LiteLLM startup helper.
- Disabled system imports for `local-ai.nix` and `secrets.nix`, so Ollama and AI
  API secrets are no longer part of the active system configuration.
- Removed `mpvpaper` from the VibeShell package environment and disabled live
  wallpaper execution in `Wallpaper.qml`.
- Forced mutable wallpaper state to a static local image during Home Manager
  activation.
- Changed default notch theme to `island`, reduced animation duration to 220ms,
  disabled corner/shadow overhead, and moved high-impact notch/dashboard
  transitions to `SpringAnimation`.
- Deferred overview, presets, screenshot overlay, mirror window, and non-critical
  service initialization so first paint happens with less startup work.

### Build Verification

Command:

```bash
nix build /etc/nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
```

Result: success on 2026-06-04. This verifies the NixOS toplevel after removing
AI files, `litellm`, `mpvpaper`, and local AI imports.

### Follow-Up Measurement

After switching and restarting VibeShell, record the real rebuilt-shell numbers:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
vibeshell quit
systemctl --user restart vibeshell.service 2>/dev/null || vibeshell >/tmp/vibeshell.log 2>&1 &
sleep 10
ps -eo pid,comm,rss,%cpu,args --sort=-rss | rg -i 'vibeshell|quickshell|mpvpaper|ollama|litellm'
systemctl --user --no-pager --type=service --state=running | rg -i 'ollama|vibeshell|mpvpaper|litellm' || true
```

Do not record a VibeShell memory improvement claim until those post-switch
numbers are captured.

## Vibeshell Optimization Follow-Up

Date: 2026-06-04

Requested correction:

- Restored notch defaults to the previous bar behavior:
  `theme = "default"` and `hoverRegionHeight = 8`.
- Restored theme defaults and mutable config behavior:
  `enableCorners = true`, `animDuration = 300`, `shadowBlur = 1`,
  `shadowOpacity = 0.5`.
- Restored the wallpaper directory to `$HOME/Pictures/wallpaper`.
- Kept the AI assistant removed completely from active VibeShell code.
- Kept live wallpaper rendering disabled by default; MP4/GIF current wallpapers
  are normalized to a static image to avoid `mpvpaper` and video-frame startup
  work.

### Validation

Commands:

```bash
nix build /etc/nixos/asuraPc/vibeshell#Vibeshell --no-link --print-out-paths
nixos-rebuild dry-build --flake /etc/nixos#nixos
```

Results:

- Local VibeShell package build: success.
- NixOS dry build: success.
- Final tested package:
  `/nix/store/7krri4mdnp36rbv492i6q52v1w0qzc75-Vibeshell`.
- Final running shell:
  `/nix/store/nbcgvmk8qrkyz0fgqrv6phlkdnnnqy0n-vibeshell-shell-0.1.0/shell.qml`.

### Screenshots

Stored under:

```text
/etc/nixos/docs/screenshots/vibeshell-optimization-2026-06-04/
```

Relevant final captures:

- `07-final-clean-bar.png`: clean default notch bar after adding explicit close.
- `08-final-dashboard-widgets.png`: widgets/dashboard launcher, no assistant tab.
- `09-final-dashboard-controls.png`: controls panel, no AI section.
- `10-final-dashboard-wallpapers.png`: wallpaper grid using
  `$HOME/Pictures/wallpaper`.
- `12-static-wallpaper-clean-bar.png`: final clean bar after static wallpaper
  normalization.

### Final Measured Runtime

Measured after restarting the local test package and waiting for startup settle.

| Component | RSS | Interval CPU | Notes |
| --- | ---: | ---: | --- |
| VibeShell `quickshell` | 524468-574532 KiB observed | 3.20% over 5.01s | Running edited shell with static current wallpaper. Later `ps` sample showed 574532 KiB RSS. |
| `mpvpaper` | not running | n/a | Live wallpaper renderer disabled by default. |
| `ollama` / `litellm` | not running | n/a | AI assistant and local AI imports removed. |
| `system_monitor.py` helper | 16220 KiB | 0.1% sampled | Existing VibeShell helper remains. |

The old generation was observed at 674668 KiB RSS plus a 474396 KiB `mpvpaper`
process after it restored an MP4 wallpaper. The optimized test generation keeps
the wallpaper directory but avoids the live renderer by default.
