# Asura NixOS Flake

Hyprland `0.55.0` + Vibeshell + Home Manager on NixOS.

## Warnings

- Replace [asuraPc/system/hardware-configuration.nix](/etc/nixos/asuraPc/system/hardware-configuration.nix) on every new machine. Do not reuse old disk, swap, or boot UUIDs.
- This repo defaults to host `nixos` and user `asura`. Change [hosts/default.nix](/etc/nixos/hosts/default.nix) if the target machine should use different names.
- Prefer Ethernet for the first install. This config supports Broadcom `wl`, but a wired link is safer if Wi-Fi lags or drops.
- Secure Boot and secrets are separate setup steps. See [docs/SECURE_BOOT.md](/etc/nixos/docs/SECURE_BOOT.md).

## Install

1. Boot a NixOS machine. If you are using the live ISO, mount the target system at `/mnt` and replace `/etc/nixos` below with `/mnt/etc/nixos`.
2. Install Git first:

```bash
nix-shell -p git
```

3. Enable flakes:

```bash
sudo mkdir -p /etc/nix
printf 'experimental-features = nix-command flakes\n' | sudo tee /etc/nix/nix.conf
```

If you are on the live ISO, write the same line to `/mnt/etc/nix/nix.conf` after the target filesystem is mounted.

4. Clone the flake:

```bash
sudo rm -rf /etc/nixos
sudo git clone https://github.com/Valo-Asura/hyprNixos.git /etc/nixos
cd /etc/nixos
```

5. Replace the hardware file for the target machine:

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
sudo install -m 0644 /tmp/hardware-configuration.nix /etc/nixos/asuraPc/system/hardware-configuration.nix
```

On the live ISO, use `sudo nixos-generate-config --root /mnt --show-hardware-config` and install the file into `/mnt/etc/nixos/asuraPc/system/hardware-configuration.nix`.

6. Build and switch:

```bash
sudo nixos-rebuild test --flake /etc/nixos#nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
sudo reboot
```

If you are on the live ISO, use:

```bash
sudo nixos-install --flake /mnt/etc/nixos#nixos
```

## First Boot

- Validate Hyprland Lua with `hyprctl reload && hyprctl configerrors`.
- If Quickshell lock fails, `vibeshell-safe-lock` falls back to `hyprlock`.
- Both lock paths use [asuraPc/hyprland/lock-images/lockscreen.png](/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png).
- More checks live in [docs/VALIDATION.md](/etc/nixos/docs/VALIDATION.md).

## Local AI

- Vibeshell memory/RAG stays enabled in config.
- Ollama startup and model loading stay disabled for the first install, so rebuilds stay fast.
- Nothing auto-pulls models during build or switch.
- Start local AI only when needed with `ai-local-start`.
- Pull the light local set with `ai-models-pull-core`.
- Check memory status in Vibeshell with `/memory`.

## Artifacts

- Generated Hyprland Lua: [hyprland.lua](/home/asura/.config/hypr/hyprland.lua)
- Shared lock image: [lockscreen.png](/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png)
- Validation notes: [docs/VALIDATION.md](/etc/nixos/docs/VALIDATION.md)

## Structure

```text
/etc/nixos
├── flake.nix
├── hosts/default.nix
├── asuraPc/system/
├── asuraPc/hyprland/
├── asuraPc/vibeshell/
├── home/
└── docs/
```

## Thanks

Thanks to the Hyprwm, Quickshell/Vibeshell, Home Manager, Stylix, Lanzaboote, nixos-hardware, sops-nix, and Caelestia-based module authors whose work and ideas were adapted here.
