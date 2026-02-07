# Host configurations
{ inputs, system, ... }:

{
  # Main laptop configuration
  nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system;
      hostname = "nixos";
      username = "asura";
    };
    modules = [
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-gpu-nvidia
      inputs.sops-nix.nixosModules.sops
      ../system
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          extraSpecialArgs = { inherit inputs system; };
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.asura = import ../home;
        };
      }
    ];
  };
}
