{ inputs, pkgs, ... }:

let
  # Toggle Switch: set to true to test vibeshellREzero (C++ native rewrite)
  # or false to keep using the standard Vibeshell (Quickshell/QML)
  useREzero = false;

  vibeshellREzeroPkg = pkgs.callPackage ../vibeshellREzero/package.nix { };
  localVibeshellPkg = import ../vibeshell/nix/packages {
    inherit pkgs;
    lib = pkgs.lib;
    self = ../vibeshell;
    system = pkgs.stdenv.hostPlatform.system;
    quickshell = inputs.quickshell;
    vibeshellLib = import ../vibeshell/nix/lib.nix { inherit (inputs) nixpkgs; };
  };

  vibeshellSafeLock = pkgs.writeShellScriptBin "vibeshell-safe-lock" ''
    set -euo pipefail

    if command -v vibeshell >/dev/null 2>&1; then
      if vibeshell lock; then
        exit 0
      fi
      echo "vibeshell lock failed, falling back to hyprlock" >&2
    fi

    if ${pkgs.procps}/bin/pgrep -x hyprlock >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pkgs.hyprlock}/bin/hyprlock
  '';

  vibeshellLockBeforeSleep = pkgs.writeShellScriptBin "vibeshell-lock-before-sleep" ''
    set -euo pipefail

    ${vibeshellSafeLock}/bin/vibeshell-safe-lock
    sleep 1
  '';

in
{
  imports = [ ../vibeshell/nix/modules ];

  programs.vibeshell = {
    enable = !useREzero;
    package = localVibeshellPkg;
    fonts.enable = true;
  };

  programs.skwd-wall.enable = true;

  environment.systemPackages = [
    vibeshellSafeLock
    vibeshellLockBeforeSleep
    pkgs.material-symbols
    pkgs.google-fonts
    pkgs.papirus-icon-theme
    pkgs.hicolor-icon-theme
  ]
  ++ (if useREzero then [ vibeshellREzeroPkg ] else [ ]);
}
