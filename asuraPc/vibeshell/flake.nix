{
  description = "Vibeshell - An Axtremely customizable shell by Axenide";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell, ... }:
    let
      vibeshellLib = import ./nix/lib.nix { inherit nixpkgs; };
    in {
      nixosModules.default = { pkgs, lib, ... }: {
        imports = [ ./nix/modules ];
        programs.vibeshell.enable = lib.mkDefault true;
        programs.vibeshell.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      packages = vibeshellLib.forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          lib = nixpkgs.lib;

          Vibeshell = import ./nix/packages {
            inherit pkgs lib self system quickshell vibeshellLib;
          };
        in {
          default = Vibeshell;
          Vibeshell = Vibeshell;
        }
      );

      devShells = vibeshellLib.forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          Vibeshell = self.packages.${system}.default;
        in {
          default = pkgs.mkShell {
            packages = [ Vibeshell ];
            shellHook = ''
              export QML2_IMPORT_PATH="${Vibeshell}/lib/qt-6/qml:$QML2_IMPORT_PATH"
              export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
              echo "Vibeshell dev environment loaded."
            '';
          };
        }
      );

      apps = vibeshellLib.forAllSystems (system:
        let
          Vibeshell = self.packages.${system}.default;
        in {
          default = {
            type = "app";
            program = "${Vibeshell}/bin/vibeshell";
          };
        }
      );
    };
}
