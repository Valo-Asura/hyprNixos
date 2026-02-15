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
      if [ -z "$1" ]; then
        echo "Usage: mount-windows /dev/sdXY [mount-point]"
        echo "Example: mount-windows /dev/sda3"
        exit 1
      fi
      
      DEVICE="$1"
      MOUNT_POINT="''${2:-/media/windows}"
      
      echo "🔧 Mounting $DEVICE to $MOUNT_POINT..."
      
      sudo mkdir -p "$MOUNT_POINT"
      sudo mount -t ntfs3 -o uid=$(id -u),gid=$(id -g),dmask=022,fmask=133 "$DEVICE" "$MOUNT_POINT"
      
      if [ $? -eq 0 ]; then
        echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT"
        echo "📁 You can now access your Windows files at: $MOUNT_POINT"
      else
        echo "❌ Failed to mount $DEVICE"
      fi
    '')
  ];
}