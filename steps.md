# NixOS Setup Notes

## Secure Boot — DONE ✅

Setup: NixOS on `sda`, Windows 11 on `nvme0n1`, GTX 1070, Zen kernel.

### What was done
1. `sudo sbctl create-keys` — generated PK/KEK/db keys at `/var/lib/sbctl`
2. `sudo sbctl enroll-keys --microsoft` — enrolled keys + Microsoft KEK into EFI vars
3. Removed the `secureBootReady` path-check conditional (Nix sandbox can't see `/var/lib`) — Lanzaboote now always enabled
4. `sudo nixos-rebuild switch` — Lanzaboote installed, signed BOOTX64.EFI + systemd-bootx64.efi
5. `sudo sbctl sign` — manually signed the zen kernel EFI
6. **Reboot → UEFI → Enable Secure Boot → done**

### Verify after reboot
```bash
sudo sbctl status
# Secure Boot: ✓ Enabled
# Setup Mode:  ✗ Disabled
```

### Rollback if broken
```bash
# In UEFI: disable Secure Boot first, then:
sudo mv /var/lib/sbctl /var/lib/sbctl.disabled
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

### Fresh Windows install note
After reinstalling Windows, run `sudo nixos-rebuild switch` — it will re-copy the Windows EFI files to the NixOS ESP automatically.

---

## Ollama / Local AI — DONE ✅

### Problem
nixpkgs-pinned ollama `0.17.0` didn't support Gemma 4. GTX 1070 (Pascal, sm_61) was excluded from the nixpkgs CUDA build (only sm_75+).

### What was done
1. Added `nixpkgs-ollama` flake input pinned to nixos-unstable HEAD (ollama `0.20.2`)
2. Passed `pkgsOllama` via `specialArgs` in `hosts/default.nix`
3. Overrode `ollama-cuda` with `cudaArches = ["61" "75" "80" "86" "90"]` to include Pascal
4. Set `MemoryDenyWriteExecute = lib.mkForce false` and `PrivateUsers = lib.mkForce false` — required for CUDA runtime
5. Set `OLLAMA_GPU_OVERHEAD = "0"` and `OLLAMA_MAX_VRAM = "8000000000"`

### Result
- `qwen3:4b` → `100% GPU`, ~42 tok/s generation, ~310 tok/s prompt
- `gemma4:e2b` → `73%/27% CPU/GPU` (7.9GB model, 7.4GB free VRAM — display eats ~600MB)
- Best model for this GPU: `qwen3:4b` (2.5GB, fully GPU-bound, fast)

### Models loaded
- `gemma4:e2b` — multimodal, partial GPU
- `qwen3:4b` — recommended, full GPU
- `qwen3:1.7b` — fastest, minimal VRAM

---

## VS Code + Windsurf — DONE ✅

Both installed via `packages.nix`. Windsurf is the primary IDE (`windsurf` command), VS Code available as `code`.
