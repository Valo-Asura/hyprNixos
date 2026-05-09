# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
  linuxEspPartUuid = "30d0727b-1228-439e-a04f-0d9402748e9d";
  windowsEspPartUuid = "98a6f918-4a0b-4479-a940-784bb92cfa77";
  plymouthTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "vibeshell-plymouth-theme";
    version = "1.0.0";
    src = ../assets/vibeshell-loading.svg;
    nativeBuildInputs = [ pkgs.librsvg ];
    dontUnpack = true;
    installPhase = ''
      theme_dir="$out/share/plymouth/themes/vibeshell"
      mkdir -p "$theme_dir"
      rsvg-convert -w 256 -h 256 "$src" -o "$theme_dir/logo.png"

      cat > "$theme_dir/vibeshell.plymouth" <<'EOF'
[Plymouth Theme]
Name=Vibeshell
Description=Quiet Vibeshell boot splash
ModuleName=script

[script]
ImageDir=/share/plymouth/themes/vibeshell
ScriptFile=/share/plymouth/themes/vibeshell/vibeshell.script
EOF

      cat > "$theme_dir/vibeshell.script" <<'EOF'
Window.SetBackgroundTopColor(0.02, 0.03, 0.04);
Window.SetBackgroundBottomColor(0.02, 0.03, 0.04);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 24);

label.image = Image.Text("Vibeshell", 0.92, 0.96, 1.00);
label.sprite = Sprite(label.image);
label.sprite.SetX(Window.GetWidth() / 2 - label.image.GetWidth() / 2);
label.sprite.SetY(Window.GetHeight() / 2 + logo.image.GetHeight() / 2 + 16);
EOF
    '';
  };
  preferSignedBootEntry = pkgs.writeShellScript "prefer-signed-boot-entry" ''
    set -euo pipefail

    if [ ! -d /sys/firmware/efi/efivars ]; then
      exit 0
    fi

    status="$(${pkgs.efibootmgr}/bin/efibootmgr 2>/dev/null || true)"
    if [ -z "$status" ]; then
      exit 0
    fi

    printf '%s\n' "$status" \
      | ${pkgs.gawk}/bin/awk '
        /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][* ]/ {
          id = substr($1, 5, 4)
          desc = substr($0, index($0, $2))
          print id "\t" desc
        }
      ' \
      | while IFS="$(printf '\t')" read -r id desc; do
        [ -n "$id" ] || continue

        should_delete=0
        case "$desc" in
          Limine*|UEFI\ OS*|*Atlas*)
            should_delete=1
            ;;
        esac

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -q '^Linux Boot Manager' \
          && ! printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -qi '${linuxEspPartUuid}'; then
          should_delete=1
        fi

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -q '^Windows Boot Manager' \
          && ! printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -qi '${windowsEspPartUuid}'; then
          should_delete=1
        fi

        if [ "$should_delete" = 1 ]; then
          ${pkgs.efibootmgr}/bin/efibootmgr -b "$id" -B || true
        fi
      done

    status="$(${pkgs.efibootmgr}/bin/efibootmgr -v 2>/dev/null || true)"
    linux_entry="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i "Linux Boot Manager.*${linuxEspPartUuid}" | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)"
    windows_entry="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i "Windows Boot Manager.*${windowsEspPartUuid}" | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)"
    current_order="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^BootOrder: //p' | ${pkgs.coreutils}/bin/head -n1)"

    if [ -z "$linux_entry" ] || [ -z "$current_order" ]; then
      exit 0
    fi

    rest="$(printf '%s\n' "$current_order" \
      | ${pkgs.gawk}/bin/awk -v linux="$linux_entry" -v windows="$windows_entry" '
        BEGIN { RS=","; ORS="" }
        $0 != linux && $0 != windows && $0 != "" {
          if (out != "") out = out ","
          out = out $0
        }
        END { print out }
      ')"

    new_order="$linux_entry"
    if [ -n "$windows_entry" ]; then
      new_order="$new_order,$windows_entry"
    fi
    if [ -n "$rest" ]; then
      new_order="$new_order,$rest"
    fi

    if [ "$new_order" != "$current_order" ]; then
      ${pkgs.efibootmgr}/bin/efibootmgr -o "$new_order" || true
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
    tpm2-tools
  ];

  boot = {
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      stage1Greeting = "";
    };

    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 12;

      systemd-boot = {
        enable = lib.mkForce false;
        editor = false;
        consoleMode = "max";
        configurationLimit = 8;
        rebootForBitlocker = true;
      };

      grub.enable = false;
      limine.enable = false;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = pkiBundle;
    };

    plymouth = {
      enable = true;
      theme = "vibeshell";
      themePackages = [ plymouthTheme ];
    };

    # Follow the newest kernel packaged by nixpkgs while keeping
    # NVIDIA/Broadcom module versions aligned with that kernel.
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
      "video=DP-1:1920x1080@165"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      # Performance
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "cryptomgr.notests"
    ];
  };

  # Optional activation-script: create sbctl keys automatically
  # Trigger file: /etc/nixos/enable-sbctl-auto-create (must be created manually)
  system.activationScripts.createSbctlKeys = {
    text = ''
      # Only run when the trigger file exists — this avoids accidental key creation
      if [ -f /etc/nixos/enable-sbctl-auto-create ]; then
        if [ ! -d ${pkiBundle} ]; then
          echo "Auto-creating Secure Boot keys (sbctl)..."
          ${pkgs.sbctl}/bin/sbctl create-keys || true
        else
          echo "sbctl key bundle already exists at ${pkiBundle}; skipping creation."
        fi
      fi
    '';
  };

  system.activationScripts.preferSignedBootEntry = {
    text = ''
      ${preferSignedBootEntry}
    '';
  };

  # Windows lives on a separate ESP on this machine. Mirror its boot manager
  # onto the NixOS ESP so systemd-boot/Lanzaboote can show it in the menu.
  system.activationScripts.syncWindowsBootEntry = {
    text = ''
      windows_esp="/dev/disk/by-partuuid/${windowsEspPartUuid}"
      mount_dir="$(${pkgs.coreutils}/bin/mktemp -d)"

      if [ -d /boot/loader/entries ]; then
        ${pkgs.coreutils}/bin/rm -f /boot/loader/entries/*[Aa]tlas*.conf
      fi

      cleanup() {
        ${pkgs.util-linux}/bin/umount "$mount_dir" >/dev/null 2>&1 || true
        ${pkgs.coreutils}/bin/rmdir "$mount_dir" >/dev/null 2>&1 || true
      }
      trap cleanup EXIT

      if [ -e "$windows_esp" ] && ${pkgs.util-linux}/bin/mount -o ro "$windows_esp" "$mount_dir" >/dev/null 2>&1; then
        if [ -f "$mount_dir/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
          ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Microsoft /boot/loader/entries
          ${pkgs.coreutils}/bin/rm -rf /boot/EFI/Microsoft/Boot
          ${pkgs.coreutils}/bin/cp -a "$mount_dir/EFI/Microsoft/Boot" /boot/EFI/Microsoft/Boot
          ${pkgs.coreutils}/bin/cat > /boot/loader/entries/windows.conf <<'EOF'
title Windows Boot Manager
efi /EFI/Microsoft/Boot/bootmgfw.efi
sort-key z_windows
EOF
        fi
      fi
    '';
  };

  # Optional activation-script: create sbctl keys automatically
  # Trigger file: /etc/nixos/enable-sbctl-auto-create (must be created manually)
  system.activationScripts.createSbctlKeys = {
    text = ''
      # Only run when the trigger file exists — this avoids accidental key creation
      if [ -f /etc/nixos/enable-sbctl-auto-create ]; then
        if [ ! -d ${pkiBundle} ]; then
          echo "Auto-creating Secure Boot keys (sbctl)..."
          ${pkgs.sbctl}/bin/sbctl create-keys || true
        else
          echo "sbctl key bundle already exists at ${pkiBundle}; skipping creation."
        fi
      fi
    '';
  };
}
