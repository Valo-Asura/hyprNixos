# Asura NixOS Vibeshell Config

A flake-based NixOS desktop for Hyprland, Vibeshell/Quickshell, local AI, gaming, and daily development.

This README is meant to be used as a checklist. Start at the top if you are moving from a clean GNOME NixOS install.

## What Changed Recently

- The shell command, module, config paths, and docs now use `vibeshell`.
- VPN/WireGuard config and UI controls were removed. Activation now deletes stale NetworkManager tunnel profiles and temporary tunnel routes from older generations.
- Archer T6E/AC1300 Wi-Fi is configured for the Broadcom BCM4360 `wl` driver path with `wpa_supplicant`, Wi-Fi power save off, and scan MAC randomization off.
- Brave was made lighter at startup by removing the always-on dark mode extension/theme setup.
- Boot no longer waits on `NetworkManager-wait-online`.
- Plymouth now shows a quiet Vibeshell boot splash.
- Hyprland starts through `vibeshell-start`, which shows a Vibeshell loading logo while Quickshell is coming up.
- Hyprland is pinned to `v0.55.0`, which has Lua config support. The current Home Manager config still emits the existing Hyprland settings so keybindings stay the same while Lua migration remains optional.
- Boot activation now removes stale firmware entries for old Limine, `UEFI OS`, Atlas, and boot managers from the wrong ESP, then orders Linux Boot Manager before Windows Boot Manager.
- The old dashboard Performance toggle page was removed, and the visual-heavy defaults are off.
- `desktop-cache-warm` now uses an absolute `awk` path, fixing the boot-time service error.
- Ollama no longer auto-downloads several large models at boot. Use `ai-models-pull-core` or `/pull core` in Vibeshell AI when you want the local chat model and embedding model.
- Vibeshell AI now uses bounded chat context plus local memory snippets for lightweight RAG.
- The bar battery/power-profile slot is now a Vibeshell settings button; Vibeshell no longer pulls in or enables `power-profiles-daemon`.
- `vibeshell reload` is guarded so repeated reload triggers collapse into one restart.
- Zed, Cursor, Docker, and OpenHands helpers are installed. Cursor downloads its upstream AppImage on first launch so rebuilds do not hang on the Cursor CDN. `openhands` installs the current CLI through `uv` on first run; `openhands-gui` starts the local Docker GUI for the current project.
- Nix store optimisation, GC, tmp cleanup, and SSD trim are automatic.

## Quick Commands

```bash
sudo nixos-rebuild test --flake /etc/nixos#nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
vibeshell reload
internet-unblock
ai-download-stop
nix-storage-clean
openhands-gui
```

Use `test` first when changing boot, GPU, login, filesystem, or network modules.

## Clean GNOME Install To This Config

These steps assume a fresh graphical NixOS install using GNOME and NetworkManager.

- [ ] Log into GNOME once and connect to the internet.
- [ ] Enable flakes.
- [ ] Copy or clone this config into `/etc/nixos`.
- [ ] Regenerate hardware config for this exact machine.
- [ ] Check username, hostname, disks, swap, and Secure Boot.
- [ ] Build with `nixos-rebuild test`.
- [ ] Switch, reboot, and log into Hyprland through greetd.

<details>
<summary>1. Enable flakes</summary>

Add this to your temporary `/etc/nixos/configuration.nix` if flakes are not already enabled:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Apply it once:

```bash
sudo nixos-rebuild switch
```

</details>

<details>
<summary>2. Put the repo in /etc/nixos</summary>

Back up the installer-generated config first:

```bash
sudo mkdir -p /etc/nixos.backup
sudo cp -a /etc/nixos/. /etc/nixos.backup/
```

Then place this repo at `/etc/nixos`.

If cloning fresh:

```bash
nix shell nixpkgs#git
sudo rm -rf /etc/nixos
sudo git clone https://github.com/Valo-Asura/hyprNixos /etc/nixos
cd /etc/nixos
```

</details>

<details>
<summary>3. Regenerate hardware config</summary>

Do not reuse another machine's disk UUIDs.

```bash
cd /etc/nixos
sudo nixos-generate-config --show-hardware-config > asuraPc/system/hardware-configuration.nix
```

Then inspect:

```bash
sed -n '1,120p' asuraPc/system/hardware-configuration.nix
```

Keep your generated `/`, `/boot`, GPU, CPU, and filesystem lines.

</details>

<details>
<summary>4. Check user and hostname</summary>

This config currently assumes:

```text
hostname: nixos
user: asura
home: /home/asura
```

If your clean GNOME install used another username, update all three places:

```text
hosts/default.nix
asuraPc/system/users.nix
home/default.nix
```

Search before rebuilding:

```bash
rg 'asura|hostname =|users\\.' /etc/nixos
```

</details>

<details>
<summary>5. Swap and zram</summary>

This config enables compressed zram swap in `asuraPc/system/performance.nix`.

If your clean GNOME install created a swap partition, keep the generated `swapDevices` line only if the UUID exists on this machine. If you do not have a real swap partition, this is fine:

```nix
swapDevices = [ ];
```

Do not paste a swap UUID from another install. That is one of the easiest ways to create boot delays or mount errors.

</details>

<details>
<summary>6. Secure Boot</summary>

Secure Boot is configured with `sbctl` and Lanzaboote in `asuraPc/system/boot.nix`.

For a clean install, use one of these paths:

Path A, keep Secure Boot:

```bash
sudo /etc/nixos/asuraPc/scripts/sbctl-create-keys.sh
sudo sbctl enroll-keys --microsoft
sudo nixos-rebuild switch --flake /etc/nixos#nixos
sudo reboot
```

Path B, first boot without Secure Boot:

Temporarily change the `enable = true;` line under `boot.lanzaboote` in `asuraPc/system/boot.nix`:

```nix
enable = false;
```

Switch and reboot first, then come back and enroll keys later.

Full notes: [docs/SECURE_BOOT.md](./docs/SECURE_BOOT.md)

</details>

<details>
<summary>7. Build, switch, reboot</summary>

```bash
cd /etc/nixos
sudo nixos-rebuild test --flake /etc/nixos#nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
sudo reboot
```

After reboot, greetd opens a text login. Log in as your user; it starts Hyprland.

</details>

## First Boot Checks

Run these after the first reboot:

```bash
systemctl --failed
journalctl -b -p err --no-pager
nmcli device status
vibeshell reload
```

The Vibeshell/Quickshell log lives here:

```bash
${XDG_STATE_HOME:-$HOME/.local/state}/Vibeshell/quickshell-launch.log
```

## Daily Use

| Task | Command |
| --- | --- |
| Rebuild | `sudo nixos-rebuild switch --flake /etc/nixos#nixos` |
| Test without making boot default | `sudo nixos-rebuild test --flake /etc/nixos#nixos` |
| Update flake inputs | `sudo nix flake update --flake /etc/nixos` |
| Reload Vibeshell | `vibeshell reload` |
| Clear DNS/model-download blockers | `internet-unblock` |
| Stop Ollama downloads | `ai-download-stop` |
| Pull light local AI models | `ai-models-pull-core` |
| Open Vibeshell settings | `SUPER+SHIFT+C` |
| Open Vibeshell settings from bar | Click the sliders/settings button |
| Open Zed | `zed .` |
| Open Cursor | `cursor .` |
| Refresh Cursor AppImage | `cursor-update` |
| Open OpenHands GUI | `openhands-gui` |
| Clean/optimise Nix store now | `nix-storage-clean` |
| Open app/dashboard widgets | `SUPER` |
| Lock | `SUPER+L` |
| Power menu | `SUPER+ESC` |

More keybinds: [docs/QUICKSHELL_BINDINGS.md](./docs/QUICKSHELL_BINDINGS.md)

## Network And Wi-Fi

- Archer T6E/AC1300 uses the Broadcom BCM4360 path. This config loads `wl` from `broadcom_sta` and blacklists the conflicting `b43`, `bcma`, `ssb`, `brcmsmac`, and `brcmfmac` modules.
- NetworkManager uses `wpa_supplicant`, not `iwd`, for this card.
- Wi-Fi power save and scan MAC randomization are disabled because both can cause lag or reconnect weirdness with Broadcom `wl`.
- `NetworkManager-wait-online` is disabled so a reconnecting Wi-Fi link does not stall boot.
- There is no declarative VPN or WireGuard service. Old NetworkManager tunnel profiles and `wg`/`tun`/`tap` routes are cleaned during activation.

If internet feels stuck or slow, clear local blockers first:

```bash
internet-unblock
nmcli -t -f NAME,TYPE,DEVICE connection show --active
ip route
```

Driver check:

```bash
lspci -k | rg -A4 -i 'network|broadcom|14e4'
```

Expected:

```text
Kernel driver in use: wl
```

Check for stale tunnel profiles or routes:

```bash
nmcli -t -f NAME,TYPE connection show | rg -i 'wireguard|vpn|tun|tap' || true
ip route
```

Quick download sample:

```bash
curl -4 -L --connect-timeout 10 --max-time 45 -o /tmp/speed.bin -w 'total=%{time_total}s speed=%{speed_download}B/s size=%{size_download}B\n' 'https://speed.cloudflare.com/__down?bytes=25000000'
rm -f /tmp/speed.bin
```

## Brave

Brave is configured in [home/desktop/browsers.nix](./home/desktop/browsers.nix).

The startup-heavy Dark Reader/theme setup was removed. If you want site dark mode again, install it manually in Brave so it is a user choice rather than a default bootstrapped extension.

## Boot And Loading

- Plymouth theme: `vibeshell`
- Logo asset: [asuraPc/assets/vibeshell-loading.svg](./asuraPc/assets/vibeshell-loading.svg)
- Hyprland startup wrapper: `vibeshell-start` in [asuraPc/hyprland/default.nix](./asuraPc/hyprland/default.nix)
- Boot module: [asuraPc/system/boot.nix](./asuraPc/system/boot.nix)
- Firmware cleanup runs during activation and keeps only the current Linux ESP and Windows ESP boot-manager entries.

The wrapper shows a logo immediately, starts `vibeshell`, then removes the temporary background after Quickshell is detected.

## Development IDEs

- Zed is installed from Nixpkgs as `zed-editor`; the `zed` command opens `zeditor`.
- Cursor runs through the `cursor` wrapper. It downloads/resumes the pinned upstream AppImage into `~/.local/share/cursor` on first launch and runs it through `appimage-run`.
- `direnv` and `nix-direnv` are enabled system-wide and in Fish/Home Manager.
- `$HOME/.local/bin`, `$HOME/.cargo/bin`, and `$HOME/go/bin` are added to the session path for uv, Rust, and Go tools.
- OpenHands is not packaged in this Nixpkgs input, so the `openhands` wrapper follows the official `uv tool install openhands --python 3.12` path on first run. `openhands-gui` runs `openhands serve --mount-cwd`.
- Docker is enabled for OpenHands sandboxes. Log out and back in after switching so the `docker` group membership is active.

## Repo Map

```text
flake.nix                         flake inputs and NixOS output
hosts/default.nix                 host/user wiring
asuraPc/system/                   NixOS modules
asuraPc/hyprland/                 Hyprland, keybinds, idle, lock
asuraPc/vibeshell/                Quickshell shell, widgets, services
home/                             Home Manager modules
docs/                             secure boot, validation, bindings
screenshots/                      reference screenshots
```

## Optional Local AI

- Ollama listens on `127.0.0.1:11434`.
- Open WebUI listens on `127.0.0.1:8080`.
- Qdrant stores Open WebUI RAG vectors on disk.
- AI defaults live in [asuraPc/vibeshell/ai.json](./asuraPc/vibeshell/ai.json).
- User API keys live in `~/.config/Vibeshell/config/ai.json`.
- Vibeshell AI commands:
  - `/pull core` downloads `qwen3:1.7b` and `nomic-embed-text`.
  - `/memory` shows local memory/RAG status.
  - `/forget` clears local memory snippets.
  - `/models` refreshes the model list.
- Shell commands:
  - `ai-models-pull-core` downloads the light local model set.
  - `ai-model-pull <model>` downloads specific Ollama models.
  - `ai-download-stop` stops active Ollama pull jobs.
- OpenClaw notes: [docs/VIBESHELL_OPENCLAW_GUIDE.md](./docs/VIBESHELL_OPENCLAW_GUIDE.md)

## Troubleshooting

<details>
<summary>Hyprland starts but the shell is missing</summary>

```bash
vibeshell reload
tail -n 120 ~/.local/state/Vibeshell/quickshell-launch.log
pgrep -af 'qs|quickshell|vibeshell'
```

</details>

<details>
<summary>Network is slow or boot waits on internet</summary>

```bash
systemctl status NetworkManager --no-pager
nmcli device status
journalctl -b -u NetworkManager --no-pager | tail -n 120
```

The config intentionally disables `NetworkManager-wait-online`, so a slow network should not block boot.

</details>

<details>
<summary>Build fails after a clean install</summary>

Check these first:

```bash
nix flake check /etc/nixos --extra-experimental-features 'nix-command flakes'
sudo nixos-rebuild test --flake /etc/nixos#nixos --show-trace
```

Common causes:

- Username is not changed everywhere.
- Hardware config still has another machine's disk UUID.
- A stale swap UUID was copied.
- Secure Boot keys were not created or Lanzaboote was not temporarily disabled.
- The SOPS age key is not restored yet.

</details>

<details>
<summary>Need to get back to GNOME</summary>

Boot a previous NixOS generation from the boot menu, or switch from a TTY:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

If you kept your backup from the clean install:

```bash
sudo cp -a /etc/nixos.backup/. /etc/nixos/
sudo nixos-rebuild switch
```

</details>
