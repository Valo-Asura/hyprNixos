{
  description = "vibeshellREzero native Wayland/OpenGL ES shell prototype";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nativeDeps = with pkgs; [
        cairo
        fontconfig
        libGL
        libxkbcommon
        meson
        ninja
        pango
        pkg-config
        wayland
        wayland-protocols
        wayland-scanner
      ];
    in
    {
      packages.${system} =
        let
          package = pkgs.callPackage ./package.nix { };
        in
        {
          default = package;
          vibeshellREzero = package;
        };

      devShells.${system}.default = pkgs.mkShell {
        packages = nativeDeps ++ (with pkgs; [
          grim
          imagemagick
          lsof
          procps
          wayland-utils
        ]);
      };
    };
}
