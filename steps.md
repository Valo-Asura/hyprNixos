# Secure Boot Setup Steps

Your setup:
- NixOS is on `sda`, boot partition at `/boot` (`sda1`)
- Windows 11 is on `nvme0n1`
- Secure Boot is currently OFF
- Right now your PC boots through **Limine** (we need to replace it with systemd-boot first)

---

## Step 1 — Reboot into systemd-boot ✅ rebuild done, do this now

Reboot:

```bash
reboot
```

If your PC still boots through Limine, go into your motherboard's one-time boot menu (usually `F8`, `F11`, or `Del` on boot) and pick **Linux Boot Manager**.

Once NixOS loads, check it worked:

```bash
bootctl status
```

You should see `systemd-boot` as the current bootloader, not Limine.

---

## Step 2 — Create Secure Boot keys

```bash
sudo sbctl create-keys
```

Check the keys were created:

```bash
sudo sbctl status
```

Now rebuild again (this time it switches to Lanzaboote):

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Reboot:

```bash
reboot
```

---

## Step 3 — Put your motherboard in Setup Mode

Go into your BIOS/UEFI settings and change these:

1. **TPM / AMD fTPM** → Enabled
2. **UEFI boot** → Enabled
3. **CSM / Legacy boot** → Disabled
4. **Secure Boot** → find the key mode and set it to **Setup Mode** or **Custom**
   - On most boards: clear the Platform Key (PK) or switch from "Standard" to "Custom"

Do NOT delete the Windows boot entry or Windows disk.

Save and reboot into NixOS (pick **Linux Boot Manager** if needed).

This boot will enroll your keys automatically (Microsoft keys are kept so Windows still works).

---

## Step 4 — Turn Secure Boot on

Go back into BIOS and set:

1. **Secure Boot** → Enabled

Save and boot NixOS.

Check it worked:

```bash
bootctl status
sbctl status
```

You want to see:
- `Secure Boot: enabled`
- `Setup Mode: Disabled`

---

## Step 5 — Check Windows still works

Boot into Windows (from the boot menu or systemd-boot menu).

In Windows:
1. Press `Win + R`, type `msinfo32` — check `Secure Boot State: On` and `BIOS Mode: UEFI`
2. Press `Win + R`, type `tpm.msc` — check TPM 2.0 is ready

If VALORANT still complains, look up `VAN 9005` — it's a VBS/Memory Integrity setting, not a Secure Boot issue.

---

## If something breaks (rollback)

1. Go into BIOS, turn **Secure Boot off**
2. Boot into NixOS via **Linux Boot Manager**
3. Run:

```bash
sudo mv /var/lib/sbctl /var/lib/sbctl.disabled
sudo nixos-rebuild switch --flake /etc/nixos#nixos
reboot
```

This drops you back to plain systemd-boot automatically.

Windows is always safe — just pick **Windows Boot Manager** from the BIOS boot menu.
