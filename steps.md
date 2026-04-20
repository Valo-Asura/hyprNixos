# Secure Boot Steps

This repo is now wired for a staged Secure Boot migration on this machine:

- NixOS disk: `sda` with ESP on `sda1` mounted at `/boot`
- Windows 11 disk: `nvme0n1` with Windows Boot Manager on `nvme0n1p1`
- Current firmware state before this change:
  - UEFI: yes
  - TPM2: yes
  - Secure Boot: off
  - Current loader: Limine

The boot module is intentionally stage-aware:

- If `/var/lib/sbctl` does not contain Secure Boot keys, the flake installs plain `systemd-boot`.
- Once keys exist, the same flake switches to `Lanzaboote` and prepares Secure Boot auto-enrollment.

## Phase 0: Preflight

Run these from NixOS:

```bash
bootctl status
sbctl status
```

Expected before Secure Boot is enabled:

- `Secure Boot: disabled`
- `TPM2 Support: yes`
- `Vendor Keys: microsoft`

Do not remove Microsoft keys. Windows 11 and device Option ROM compatibility depend on them.

## Phase 1: Migrate Off Limine

Apply the new flake once:

```bash
sudo nixos-rebuild boot --flake /etc/nixos#nixos
```

Reboot.

If the machine still comes up through Limine, use your motherboard one-time boot menu and choose:

- `Linux Boot Manager`

Once back in NixOS, confirm the migration:

```bash
bootctl status
```

At this point the current boot loader should no longer be `Limine`.

## Phase 2: Create Secure Boot Keys

Create the signing keys in the default `sbctl` location:

```bash
sudo sbctl create-keys
```

Sanity check:

```bash
sudo sbctl status
sudo find /var/lib/sbctl -maxdepth 3 -type f | sort
```

Rebuild again. This second rebuild is the one that turns on Lanzaboote:

```bash
sudo nixos-rebuild boot --flake /etc/nixos#nixos
```

## Phase 3: Put Firmware In Setup Mode

Reboot into firmware setup.

Required firmware settings:

1. `TPM` or `AMD fTPM`: `Enabled`
2. `UEFI boot`: `Enabled`
3. `CSM/Legacy boot`: `Disabled`
4. Secure Boot key mode: switch to `Custom` or `Setup Mode`

On many boards, `Setup Mode` is reached by clearing the current Secure Boot Platform Key (`PK`) or switching Secure Boot from `Standard` to `Custom`.

Do not delete the Windows disk or Windows boot entry.

Save changes and boot back into NixOS through:

- `Linux Boot Manager`

Because `boot.lanzaboote.autoEnrollKeys.enable = true`, this boot should prepare and perform key enrollment for your own keys while keeping Microsoft keys included.

## Phase 4: Turn Secure Boot On

Reboot into firmware again.

Now enable:

1. `Secure Boot`: `Enabled`

Save and boot NixOS again.

Validate from NixOS:

```bash
bootctl status
sbctl status
```

Expected:

- `Secure Boot: enabled`
- `Setup Mode: Disabled`

## Phase 5: Validate Windows 11 + VALORANT

Boot Windows from the firmware menu or from the systemd-boot menu if `Windows Boot Manager` appears there.

In Windows:

1. Press `Win + R`, run `msinfo32`
2. Confirm:
   - `BIOS Mode`: `UEFI`
   - `Secure Boot State`: `On`
3. Press `Win + R`, run `tpm.msc`
4. Confirm TPM is ready and version `2.0`

If VALORANT still complains after Secure Boot and TPM are both on, check Riot's `VAN 9005` guidance for VBS/Memory Integrity before changing anything else.

## Rollback

If NixOS does not boot after enrollment:

1. Enter firmware
2. Set `Secure Boot` back to `Disabled`
3. Boot `Linux Boot Manager`

Once back in NixOS, force the flake back to plain systemd-boot by moving the signing bundle out of the way:

```bash
sudo mv /var/lib/sbctl /var/lib/sbctl.disabled
sudo nixos-rebuild boot --flake /etc/nixos#nixos
```

Reboot again.

Because the flake checks for `/var/lib/sbctl` at evaluation time, removing that directory automatically drops it back to stage 1.

Windows rollback is simple:

- use the firmware boot picker and select `Windows Boot Manager`

## Quick Command Summary

```bash
sudo nixos-rebuild boot --flake /etc/nixos#nixos
reboot

sudo sbctl create-keys
sudo nixos-rebuild boot --flake /etc/nixos#nixos
reboot
```
