# Secure Boot Instructions

This host uses `lanzaboote` plus `sbctl`. Nix can build and sign the boot artifacts, but it cannot flip the firmware Secure Boot switch for you.

## Current Layout

- ESP mount: `/boot`
- Secure Boot key bundle: `/var/lib/sbctl`
- Declarative module: `/etc/nixos/asuraPc/system/boot.nix`
- Signed boot entry: `Linux Boot Manager`
- Windows entry: `Windows Boot Manager`
- Old/stale entry that should not be first: `Limine`

The Nix activation script now prefers `Linux Boot Manager` in EFI BootOrder when that entry exists. Systemd-boot is configured with `rebootForBitlocker`, so selecting Windows from the Linux boot menu reboots through firmware BootNext instead of chainloading Windows directly. That keeps BitLocker PCR measurements aligned with Secure Boot.

## One-Time Setup

Back up the ESP before enrolling keys:

```bash
sudo tar -C /boot -caf "$HOME/esp-backup-$(date +%F).tar.zst" .
```

Create keys if `/var/lib/sbctl` does not exist:

```bash
sudo /etc/nixos/asuraPc/scripts/sbctl-create-keys.sh
```

For Windows dual boot, preserve Microsoft vendor keys:

```bash
sudo sbctl enroll-keys --microsoft
```

Rebuild and reboot:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
sudo reboot
```

Enter UEFI setup, make sure `Linux Boot Manager` is the first Linux boot entry, then enable Secure Boot.

## Verify

After booting back into NixOS:

```bash
sbctl status
bootctl status --no-pager
sudo sbctl verify
efibootmgr -v
```

Expected state:

- `sbctl status` shows `Installed: yes`
- `Setup Mode` is disabled
- `Secure Boot` is enabled
- `bootctl status` reports Secure Boot enabled
- `efibootmgr` has `Linux Boot Manager` before Limine

## Recovery Notes

- If Windows or Atlas OS asks for BitLocker recovery from the Linux boot menu, choose `Windows Boot Manager` once from firmware boot override and then rebuild NixOS so the systemd-boot BitLocker handoff and stale Atlas/Windows loader entries are refreshed.
- If Windows stops booting, re-enroll with `sudo sbctl enroll-keys --microsoft`.
- If firmware boots Limine first, select `Linux Boot Manager` in UEFI or run `sudo nixos-rebuild switch --flake /etc/nixos#nixos` again so the activation script can rewrite BootOrder.
- If the machine does not boot, use firmware boot override to pick Windows Boot Manager or a NixOS installer, then restore the ESP backup if needed.
- Do not delete `/var/lib/sbctl` after enrolling. It is the signing key bundle used by future rebuilds.
