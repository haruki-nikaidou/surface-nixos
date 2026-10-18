{
  description = "Haruki's NixOS profile for the Surface Laptop 7";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware support (kernel, device tree, firmware) from ../installer.
    x1e = {
      url = "path:../installer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      x1e,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos-surface = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          x1e.nixosModules.x1e
          ./system/index.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.haruki = import ./user/index.nix;
          }
        ];
      };
    };
}
