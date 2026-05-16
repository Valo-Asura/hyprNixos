# Windows Drive Mount Helper
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "find-windows-drives" ''
      echo "🔍 Scanning for Windows drives..."
      echo "=================================="
      
      # List all block devices
      lsblk -f | grep -E "(ntfs|exfat|vfat)" || echo "No Windows drives found"
      
      echo ""
      echo "📁 Available mount points:"
      ls -la /media/ 2>/dev/null || echo "No mounted drives in /media/"
      
      echo ""
      echo "🔧 To manually mount a Windows drive:"
      echo "sudo mkdir -p /media/windows"
      echo "sudo mount -t ntfs3 /dev/sdXY /media/windows"
      echo ""
      echo "Replace /dev/sdXY with your Windows partition (e.g., /dev/sda3)"
    '')
    
    (pkgs.writeShellScriptBin "mount-windows" ''
      MODE="rw"
      if [ "''${1:-}" = "--ro" ] || [ "''${1:-}" = "-r" ]; then
        MODE="ro"
        shift
      fi

      if [ -z "''${1:-}" ]; then
        echo "Usage: mount-windows [--ro] /dev/sdXY [mount-point]"
        echo "Example: mount-windows --ro /dev/sda2 '/media/New Volume'"
        exit 1
      fi
      
      DEVICE="$1"
      MOUNT_POINT="''${2:-/media/windows}"
      OPTIONS="uid=$(id -u),gid=$(id -g),dmask=022,fmask=133"
      if [ "$MODE" = "ro" ]; then
        OPTIONS="ro,$OPTIONS"
      fi
      
      echo "🔧 Mounting $DEVICE to $MOUNT_POINT ($MODE)..."

      sudo mkdir -p "$MOUNT_POINT"
      if sudo mount -t ntfs3 -o "$OPTIONS" "$DEVICE" "$MOUNT_POINT"; then
        echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT"
        echo "📁 You can now access your Windows files at: $MOUNT_POINT"
        exit 0
      fi

      if [ "$MODE" = "rw" ]; then
        echo "⚠️  Read-write mount failed. Trying safe read-only mount..."
        if sudo mount -t ntfs3 -o "ro,uid=$(id -u),gid=$(id -g),dmask=022,fmask=133" "$DEVICE" "$MOUNT_POINT"; then
          echo "✅ Mounted read-only at $MOUNT_POINT"
          echo "⚠️  For write access, repair the NTFS volume from Windows:"
          echo "   chkdsk /f <drive-letter>:"
          exit 0
        fi
      fi

      echo "❌ Failed to mount $DEVICE"
      echo "If kernel logs mention a dirty NTFS volume, use Windows chkdsk before write-mounting."
      exit 1
    '')
  ];
}
