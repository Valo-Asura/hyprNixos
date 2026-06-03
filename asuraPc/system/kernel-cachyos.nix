# CachyOS kernel integration.
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Use the pinned overlay so the selected CachyOS kernel matches the upstream
  # binary cache. The Ryzen 5 5600G is Zen3, so use x86_64-v3 instead of zen4.
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  nix.settings = {
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
}
