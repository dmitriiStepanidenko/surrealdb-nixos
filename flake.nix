{
  description = "Surrealdb bin with version picking and service";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        manifests = import ./manifests;
      in {
        packages = let
          versionedPackages =
            (pkgs.callPackage ./lib/todo-backend-bin.nix {inherit manifests;}).packages;
        in
          versionedPackages
          // {
            #default = self.packages.${system}.todo-backend.stable;
            #default = self.packages.${system}.todo-backend.packages.stable;
            #todo-backend = versionedPackages.stable;
            #pkgs.lib.mapAttrs (version: deriv: { "${version}"= deriv; }) versionedPackages;
          };
      }
    )
    // {
      # NixOS module that can be imported in configuration.nix
      nixosModules.default = import ./module.nix;

      # For backward compatibility
      nixosModule = self.nixosModules.default;
    };
}
