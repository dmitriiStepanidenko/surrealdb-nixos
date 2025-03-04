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
        mkDerivationSet = pkgs.callPackage ./lib/mkDerivation.nix {};
      in {
        packages = let
          versionedPackages = pkgs.lib.mapAttrs (version: manifest:
            mkDerivationSet {inherit (manifest) version hash;} {})
          manifests;
        in
          versionedPackages
          // {
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
