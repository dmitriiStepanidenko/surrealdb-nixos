# surrealdb-nixos

SurrealDB binary packages for Flake-enabled NixOS with the ability to choose specific versions.

Current latest version: 2.3.1
Current latest_unstable version: 3.0.0-alpha.3

# Usage example 
Add this input to flake.nix:
```nix
{
  inputs = {
    surrealdb.url = "github:dmitriiStepanidenko/surrealdb-nixos";
    # ...
  };
}
```

Somewhere in your configuration add:
```nix
  imports = [
    inputs.surrealdb.nixosModules.default
  ];

  config = {
    services.surrealdb-bin = {
      enable = true;
      package = inputs.surrealdb.packages.${system}.latest;
      auth = {
        username = "root";
        passwordFile = config.sops.secrets."surrealdb/password".path;
      };
    };
  };
```

All available versions are defined in ./manifests/default.nix. Note that versions can be referenced as either "x.y.z" or "x_y_z" - both formats refer to the same version. The underscore format is used for CLI commands like nix build .#x_y_z.


# Todo
- [ ] Currently this library only supports services with RocksDB backend for SurrealDB
- [ ] Add GitHub Actions to automatically update to new versions when released

