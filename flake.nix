{
  description = "NixOS installer ISO for Surface Laptop 7 (Snapdragon X Elite)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Build natively for aarch64 (uses binfmt/QEMU emulation on x86_64 hosts)
      targetSystem = "aarch64-linux";

      pkgs = import nixpkgs {
        system = targetSystem;
        config.allowUnfree = true;
      };

      # For dev shell on x86_64
      pkgsNative = nixpkgs.legacyPackages."x86_64-linux";

    in
    {
      # The installer ISO (build with: nix build .#iso)
      packages.${targetSystem} = {
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;

        # Useful for debugging - just build the kernel
        kernel = self.nixosConfigurations.installer.config.boot.kernelPackages.kernel;
      };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        system = targetSystem;
        inherit pkgs;

        modules = [
          ./modules/kernel.nix
          ./modules/installer.nix
          ./modules/hardware.nix
        ];
      };

      # Dev shell for working on this
      devShells."x86_64-linux".default = pkgsNative.mkShell {
        buildInputs = with pkgsNative; [
          qemu
          nix-prefetch-git
          nix-prefetch-github
        ];
      };
    };
}
