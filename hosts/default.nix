# Host configurations
{ inputs, system, ... }:

{
<<<<<<< HEAD
  # Main PC configuration
=======
  # Main laptop configuration
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
  nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system;
      hostname = "nixos";
      username = "asura";
<<<<<<< HEAD
      pkgsOllama = import inputs.nixpkgs-ollama {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = false;
      };
    };
    modules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-cpu-amd
=======
    };
    modules = [
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-gpu-nvidia
>>>>>>> 885a97f (NixOS performance optimizations & ambxst widget fixes)
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
