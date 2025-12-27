{
  description = "NixOS installer ISO for Surface Laptop 7 (Snapdragon X Elite)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Build on x86_64, target aarch64
      buildSystem = "x86_64-linux";
      targetSystem = "aarch64-linux";

      pkgsNative = nixpkgs.legacyPackages.${buildSystem};

      # Cross-compilation pkgs
      pkgsCross = import nixpkgs {
        localSystem = buildSystem;
        crossSystem = {
          config = "aarch64-unknown-linux-gnu";
          system = targetSystem;
        };
        config.allowUnfree = true;
      };

    in
    {
      # The installer ISO
      packages.${buildSystem} = {
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;

        # Useful for debugging - just build the kernel
        kernel = self.nixosConfigurations.installer.config.boot.kernelPackages.kernel;
      };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        system = targetSystem;
        pkgs = pkgsCross;

        modules = [
          # Cross-compilation setup
          (
            { ... }:
            {
              nixpkgs.buildPlatform = buildSystem;
              nixpkgs.hostPlatform = targetSystem;
              nixpkgs.config.allowUnfree = true;
            }
          )

          # Import our custom modules
          ./modules/kernel.nix
          ./modules/installer.nix
          ./modules/hardware.nix
        ];
      };

      # Dev shell for working on this
      devShells.${buildSystem}.default = pkgsNative.mkShell {
        buildInputs = with pkgsNative; [
          qemu
          nix-prefetch-git
          nix-prefetch-github
        ];
      };
    };
}
