<<<<<<< HEAD
# Asura NixOS Vibeshell Config

A flake-based NixOS desktop for Hyprland, Vibeshell/Quickshell, local AI, gaming, and daily development.

This README is meant to be used as a checklist. Start at the top if you are moving from a clean GNOME NixOS install.

## What Changed Recently

- The shell command, module, config paths, and docs now use `vibeshell`.
- WireGuard imports now use safer NetworkManager settings: no autoconnect, lower MTU, explicit WireGuard default-route handling, disabled IPv6 on imported profiles, and loose reverse-path filtering for VPN routing.
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
vpn-off
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
| Clear VPN/download blockers | `internet-unblock` |
| Force no VPN | `vpn-off` |
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

## Network And VPN

- NetworkManager uses `wpa_supplicant`, which is required for the Broadcom BCM4360 path in this config.
- `NetworkManager-wait-online` is disabled so flaky Wi-Fi, USB tethering, or VPN profiles do not stall boot.
- WireGuard tools are installed.
- The declarative placeholder profile in `asuraPc/system/vpn.nix` stays disabled until real peer data exists.
- Vibeshell can import a WireGuard `.conf` from the clipboard into NetworkManager.
- Imported VPNs do not autoconnect and do not take the default route unless you deliberately change the profile.

If internet feels stuck or slow, clear local blockers first:

```bash
internet-unblock
nmcli -t -f NAME,TYPE,DEVICE connection show --active
ip route
```

To inspect VPN profiles:

```bash
nmcli -t -f NAME,TYPE connection show | rg 'wireguard|vpn'
```

If internet slows or stops only while a VPN is active, check MTU and routes:

```bash
nmcli connection show <vpn-name> | rg 'wireguard.mtu|peer-routes|auto-default|ipv6.method'
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
=======
# 🚀 Asura's NixOS Laptop Configuration

*"Because life's too short for broken configs and ugly desktops"* 😎

A meticulously crafted NixOS configuration that actually works™️. Built with love, caffeine, and an unhealthy obsession with dotfiles.

## 📸 Screenshots

![Lockscreen](./screenshots/lockscreen.png)
![Desktop](./screenshots/Screenshot_2026-02-03-18-44-51.png)

## 🏗️ System Architecture

```
nixos-laptop/
├── 📁 asuraLaptop/          # Main system configuration
│   ├── 🎨 hyprland/         # Wayland compositor setup
│   ├── 🖥️  system/          # Core system modules
│   ├── 📜 scripts/          # Custom automation scripts
│   └── 🎭 ags/              # Desktop widgets & panels
├── 🏠 home/                 # Home Manager configuration
│   ├── 🐚 shell/            # Fish shell + Starship prompt
│   ├── �e️  desktop/         # GTK theming & desktop apps
│   ├── 💻 vscode/           # Kiro IDE configuration
│   └── 📦 templates/        # Direnv project templates
├── 🌐 hosts/               # Host-specific configurations
└── 📋 flake.nix            # The magic happens here
```

**What makes this special?**
- 🎯 **Modular Design**: Each component is isolated and reusable
- 🔥 **Stylix Integration**: System-wide theming that doesn't suck
- ⚡ **Performance Optimized**: Because waiting is for peasants
- 🛠️ **Developer Friendly**: Direnv, modern CLI tools, and sanity
- 🎨 **Actually Pretty**: Dark theme that won't burn your retinas

## 🧠 Ambxst AI (Cloud + Local)

**Default model:** `gpt-4o-mini`  
**Auto fallback:** If OpenAI hits rate limits and Gemini is available, Ambxst switches to Gemini automatically.

**Set API keys (recommended)**
- In Ambxst chat, run: `/key openai sk-...`
- Optional Gemini fallback: `/key gemini <key>`
- Keys are stored in `~/.config/Ambxst/config/ai.json`

**If key saving fails (permission denied)**
```bash
sudo chown -R $USER:$USER ~/.config/Ambxst
```

**Local AI (LM Studio)**
- Guide: `/home/asura/Downloads/AMBXST_LMSTUDIO_GUIDE.md`
- Config files:
  - `/etc/nixos/asuraLaptop/ambxst/modules/services/ai/litellm_config.yaml`
  - `/etc/nixos/asuraLaptop/ambxst/ai.json` (repo defaults)
  - `~/.config/Ambxst/config/ai.json` (user overrides)

## 🖼️ Ambxst Wallpapers

**Wallpaper config file (user state):**
- `~/.local/share/Ambxst/wallpapers.json`

Key fields inside:
- `wallPath`: directory Ambxst scans for wallpapers
- `currentWall`: full path to the selected wallpaper

**Recommended folder:**
- `~/Pictures/Wallpapers`

**How to set it**
1. Put your wallpapers in `~/Pictures/Wallpapers`.
2. Open the Ambxst wallpaper UI:
   - Keybind: `SUPER` + `,` (comma), or run `ambxst run dashboard-wallpapers`.
3. Set the wallpaper directory and pick a wallpaper.

**Manual edit (if you prefer)**
Edit `~/.local/share/Ambxst/wallpapers.json` and set:
```
"wallPath": "/home/asura/Pictures/Wallpapers",
"currentWall": "/home/asura/Pictures/Wallpapers/your-image.png"
```

Supported types: `jpg`, `png`, `webp`, `gif`, `mp4`, `webm`, `mkv`.

## 🚀 Quick Setup (Flake Workflow)

### 0) Prerequisites
```bash
# Enable flakes in /etc/nixos/configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### 1) Install Git (if not already)
```bash
nix-shell -p git
```

### 2) Clone This Repo
```bash
git clone https://github.com/Valo-Asura/hyprNixos /etc/nixos
cd /etc/nixos
```

### 3) Replace Hardware Config
```bash
sudo nixos-generate-config --show-hardware-config > asuraLaptop/system/hardware-configuration.nix
```

### 4) Update Host/User (if needed)
Edit `hosts/default.nix` if your hostname/username differ.

### 5) Build & Switch
```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

### 6) Reboot
```bash
sudo reboot
```

## 🎭 Replicating This Setup

### For Other NixOS Systems
1. **Fork this repo** (because copying is caring)
2. **Update hardware-configuration.nix** with your hardware
3. **Modify hosts/default.nix** with your hostname/username
4. **Adjust asuraLaptop/** folder name to match your setup
5. **Tweak theming.nix** if you hate Gruvbox (but why would you?)
6. **Run `rebuild`** and pray to the Nix gods

### For Non-NixOS Systems
*"Why would you do this to yourself?"* 🤔
- Use Home Manager standalone
- Copy the `home/` directory structure
- Install packages manually (like a caveman)
- Cry because it's not as elegant

## � Tearminal & Shell Setup

### 🎨 Kitty Terminal Features
- **Font**: JetBrainsMono Nerd Font (15pt) + FiraCode Nerd Font
- **Size**: 120 columns × 25 rows (optimized for productivity)
- **Style**: Powerline tabs with round edges
- **Theme**: Gruvbox dark with 92% opacity
- **Cursor**: Trail effect for better visibility

### ⚡ Enhanced Fish Shell
- **Starship Prompt**: Gruvbox-themed with Git & direnv indicators
- **Smart Tools**:
  - `atuin` - AI-powered shell history
  - `zoxide` - Smart cd replacement (`z` command)
  - `fzf` - Fuzzy finder integration
  - `eza` - Modern ls with icons & Git status
  - `bat` - Syntax-highlighted cat
  - `ripgrep` - Fast grep replacement
- **Fun Quotes**: Random developer/tech quotes on terminal startup
- **Motivational System**: Context-aware quotes for different coding moods

### 🚀 Quick Commands
```bash
ff                   # FastFetch system info
z <directory>        # Smart directory jumping
ctrl+r               # Atuin history search (in terminal)
quote                # Random fun quote
qotd                 # Quote of the day
motivate <mood>      # Motivational quotes (debug/frustrated/tired/confident)
```

## 🖼️ Wallpaper Management

### Change Wallpaper
```bash
hyprctl hyprpaper wallpaper "eDP-1,/path/to/image.jpg"    # Set wallpaper for main display
hyprctl hyprpaper wallpaper ",/path/to/image.jpg"         # Set for all displays
```

### Live Wallpaper
```bash
swww init                                                  # Initialize live wallpaper daemon
swww img /path/to/image.jpg                               # Set static image
swww img /path/to/video.mp4                               # Set video as wallpaper
```

## 🔧 System Commands

### Enhanced System Info
```bash
sysinfo              # Detailed system information
microfetch-custom    # Enhanced microfetch (alias: mf)
thermal-status       # Thermal management status
```

### Project Management
```bash
init-project <name> <type>  # Create new project with direnv
init-envrc <template>       # Add .envrc to existing project
mkcd <directory>            # Create and enter directory
```

### Development Shortcuts
```bash
rebuild              # nixos-rebuild switch --flake .
update               # nix flake update
clean                # nix-collect-garbage -d
code                 # Launch Kiro
```

## 🤖 Ambxst + OpenClaw AI

If you want the AI dashboard working out of the box (Ambxst → LiteLLM → OpenClaw), follow:

`docs/AMBXST_OPENCLAW_GUIDE.md`

## 🧩 Ambxst Keybinds

Thanks to Ambxst for the beautiful QuickShell config.

### Dashboard
| Keybind | Action |
| --- | --- |
| `SUPER+A` | Dashboard Assistant |
| `SUPER+V` | Dashboard Clipboard |
| `SUPER+.` | Dashboard Emoji |
| `SUPER+N` | Dashboard Notes |
| `SUPER+T` | Dashboard Tmux |
| `SUPER+,` | Dashboard Wallpapers |
| `SUPER` (hold) | Dashboard Widgets (hold) |

### System
| Keybind | Action |
| --- | --- |
| `SUPER+SHIFT+C` | Ambxst Config |
| `SUPER+SHIFT+A` | Ambxst Lens |
| `SUPER+L` | Lock Screen |
| `SUPER+TAB` | Overview |
| `SUPER+ESC` | Power Menu |
| `SUPER+CTRL+ALT+B` | Ambxst Quit |
| `SUPER+ALT+B` | Ambxst Reload |
| `SUPER+SHIFT+R` | Screen Record |
| `SUPER+SHIFT+S` | Screenshot |
| `SUPER+S` | Tools |

### Window & Workspace
| Keybind | Action |
| --- | --- |
| `SUPER+C` | Close Window |
| `SUPER+1..0` | Switch to Workspace 1..10 |
| `SUPER+SHIFT+1..0` | Move Window to Workspace 1..10 |
| `SUPER+V` | Previous Workspace |
| `SUPER+X` | Next Workspace |
| `SUPER+SHIFT+Z` | Previous Occupied Workspace |
| `SUPER+SHIFT+X` | Next Occupied Workspace |
| `SUPER+Scroll Down` | Previous Occupied Workspace |
| `SUPER+Scroll Up` | Next Occupied Workspace |
| `SUPER+SHIFT+V` | Toggle Special Workspace |
| `SUPER+ALT+V` | Move Window to Special Workspace |

### Focus & Move
| Keybind | Action |
| --- | --- |
| `SUPER+Up` / `SUPER+CTRL+K` | Focus Up |
| `SUPER+Down` / `SUPER+CTRL+J` | Focus Down |
| `SUPER+Left` / `SUPER+CTRL+H` | Focus Left |
| `SUPER+Right` / `SUPER+CTRL+L` | Focus Right |
| `SUPER+SHIFT+Up` / `SUPER+SHIFT+K` | Move Window Up |
| `SUPER+SHIFT+Down` / `SUPER+SHIFT+J` | Move Window Down |
| `SUPER+SHIFT+Left` / `SUPER+SHIFT+H` | Move Window Left |
| `SUPER+SHIFT+Right` / `SUPER+SHIFT+L` | Move Window Right |
| `SUPER+Mouse Left` | Drag Window |
| `SUPER+Mouse Right` | Resize Window |

### Resize & Layout
| Keybind | Action |
| --- | --- |
| `SUPER+ALT+Left` / `SUPER+ALT+H` | Resize Horizontal - |
| `SUPER+ALT+Right` / `SUPER+ALT+L` | Resize Horizontal + |
| `SUPER+ALT+Up` / `SUPER+ALT+K` | Resize Vertical - |
| `SUPER+ALT+Down` / `SUPER+ALT+J` | Resize Vertical + |
| `SUPER+ALT+SPACE` | Promote (Scrolling) |
| `SUPER+CTRL+SPACE` | Toggle Fit (Scrolling) |
| `SUPER+SHIFT+SPACE` | Toggle Full Column (Scrolling) |
| `SUPER+ALT+CTRL+Left` / `SUPER+ALT+CTRL+H` | Swap Column Left |
| `SUPER+ALT+CTRL+Right` / `SUPER+ALT+CTRL+L` | Swap Column Right |
| `SUPER+CTRL+ALT+1..0` | Move Column to Workspace 1..10 |

### Media & Hardware
| Keybind | Action |
| --- | --- |
| `XF86AudioPlay` / `XF86AudioMedia` | Play/Pause |
| `XF86AudioPrev` | Previous Track |
| `XF86AudioNext` | Next Track |
| `XF86AudioStop` | Stop |
| `XF86AudioRaiseVolume` | Volume Up |
| `XF86AudioLowerVolume` | Volume Down |
| `XF86AudioMute` | Mute |
| `XF86MonBrightnessUp` | Brightness Up |
| `XF86MonBrightnessDown` | Brightness Down |
| `XF86Calculator` | Calculator |
| `Lid Close` | Lock Session |
| `Lid Close (on)` | Display Off |
| `Lid Open (off)` | Display On |

### Power & Thermal
```bash
power-status         # Check power management status
power-optimize       # Optimize settings based on AC/battery
thermal-monitor      # Real-time thermal monitoring
acpi-diagnostics     # Diagnose ACPI/EC issues
```

### Fun & Productivity
```bash
quote                # Random developer quote
qotd                 # Quote of the day
motivate <mood>      # Motivational quotes (debug/frustrated/tired/confident)
fix-nemo-thumbnails  # Fix file manager thumbnail permissions
restart-nemo         # Restart Nemo file manager
```

## 🎯 Features That Actually Matter

- **🔥 Stylix Theming**: Consistent dark theme across everything (including browsers!)
- **⚡ Direnv Integration**: Automatic environment management
- **🐚 Enhanced Shell**: Fish + Starship + modern CLI tools + fun quotes
- **🛠️ Developer Tools**: Kiro IDE, nixfmt, language servers
- **🌡️ Thermal Management**: Because laptops shouldn't be space heaters
- **🔋 Power Optimization**: Battery life that doesn't suck
- **🎨 Hyprland**: Wayland compositor that actually works
- **📁 File Management**: Nemo with working thumbnails (no more permission errors!)
- **🌐 Browser Theming**: Dark theme for Zen browser and Firefox
- **💭 Fun Quotes**: Random developer wisdom to brighten your terminal

## 🤝 Contributing

Found a bug? Want to add something cool? PRs welcome!

*"Just don't break my beautiful config, please"* 🙏

---

*Made with ❤️, lots of ☕, and probably too much 🍕*
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
