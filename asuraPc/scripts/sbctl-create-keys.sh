#!/usr/bin/env bash
set -euo pipefail

if ! command -v sbctl >/dev/null 2>&1; then
  echo "sbctl not found. Install sbctl (it's in environment.systemPackages) and try again."
  exit 1
fi

cat <<'EOF'
This helper will create Secure Boot keys using `sbctl` and place them in /var/lib/sbctl.
It does NOT enroll keys into firmware. After creation you should enroll keys manually
(or use `sbctl enroll-keys`) and then rebuild the system to enable Lanzaboote.

Steps this script performs:
  1) Run `sbctl create-keys`
  2) Show the key locations and next steps
EOF

read -r -p "Proceed to create keys now? (y/N) " answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Aborted by user."; exit 1;;
esac

sudo sbctl create-keys

echo
echo "Keys created under /var/lib/sbctl:"
ls -l /var/lib/sbctl || true

echo
echo "Next steps:"
echo " 1) Inspect the keys in /var/lib/sbctl"
echo " 2) Enroll keys with: sudo sbctl enroll-keys"
echo " 3) Rebuild the NixOS configuration: sudo nixos-rebuild switch --flake /etc/nixos#nixos"
echo " 4) Reboot and verify Secure Boot state"

exit 0
