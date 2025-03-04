{
  description = "Surrealdb pre-build executable";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      makeSurrealdb = { version, srcHash, cargoHash, rocksdb}: 
        pkgs.callPackage ./surrealdb_src.nix {
          inherit version srcHash cargoHash;
      };
    in {
      #packages.default = pkgs.callPackage ./default.nix {};
      packages = {
        default = self.packages.${system}.v2_0_2;
        
        v2_2_0 = makeSurrealdb {
          version = "2.2.0";
          srcHash = "sha256-gsIeoxSfbHHSdpPn6xAB/t5w3cLtpu6MjTuf5xsI6wI=";
          cargoHash = "sha256-OXcQsDCiT3seMQhyKEKfC8pcd4MXwbql5+ZDGGkhPMI=";
          rocksdb = pkgs: pkgs.rocks;
        };

        v2_0_2 = makeSurrealdb {
          version = "2.0.2";
          srcHash = "sha256-kTTZx/IXXJrkC0qm4Nx0hYPbricNjwFshCq0aFYCTo0="; 
          cargoHash = "sha256-K62RqJqYyuAPwm8zLIiASH7kbw6raXS6ZzINMevWav0="; 
          #rocksdb = pkgs: pkgs.rocks_8_11;
          rocksdb = pkgs: pkgs.rocks;
        };
      };
    });
}
