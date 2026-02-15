# Fix Nemo Thumbnail Cache Permissions
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "fix-nemo-thumbnails" ''
      #!/bin/bash

      echo "🔧 Fixing Nemo thumbnail cache permissions..."

      # Create necessary directories
      mkdir -p ~/.cache/thumbnails/{normal,large,fail}
      mkdir -p ~/.cache/nemo
      mkdir -p ~/.local/share/nemo

      # Fix ownership and permissions
      sudo chown -R $USER:users ~/.cache/thumbnails
      sudo chown -R $USER:users ~/.cache/nemo
      sudo chown -R $USER:users ~/.local/share/nemo

      chmod -R 755 ~/.cache/thumbnails
      chmod -R 755 ~/.cache/nemo
      chmod -R 755 ~/.local/share/nemo

      # Clear existing thumbnail cache
      echo "🗑️  Clearing old thumbnail cache..."
      rm -rf ~/.cache/thumbnails/*
      rm -rf ~/.cache/nemo/*

      # Restart thumbnail service
      echo "🔄 Restarting thumbnail services..."
      pkill -f tumbler || true

      # Test thumbnail generation
      echo "✅ Testing thumbnail generation..."
      if command -v tumbler >/dev/null 2>&1; then
        echo "Tumbler service available"
      else
        echo "⚠️  Tumbler service not found - thumbnails may not work"
      fi

      echo "✅ Nemo thumbnail permissions fixed!"
      echo "💡 Restart Nemo to see changes: pkill nemo && nemo &"
    '')

    (pkgs.writeShellScriptBin "restart-nemo" ''
      #!/bin/bash
      echo "🔄 Restarting Nemo file manager..."
      pkill nemo 2>/dev/null || true
      sleep 1
      nemo &
      echo "✅ Nemo restarted"
    '')
  ];
}
