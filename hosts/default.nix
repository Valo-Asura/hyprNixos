# Host configurations
{ inputs, system, ... }:

{
  # Main PC configuration
  nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system;
      hostname = "nixos";
      username = "asura";
      pkgsOllama = import inputs.nixpkgs-ollama {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
    };
    modules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-cpu-amd
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
