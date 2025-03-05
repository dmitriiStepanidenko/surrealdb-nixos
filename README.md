# surrealdb-nixos

SurrealDB binary packages for Flake-enabled NixOS with the ability to choose specific versions.

# Usage example 
Add this input to flake.nix:
```nix
{
  inputs = {
    surrealdb.url = "path:/home/dmitrii/shared/tmp/surrealdb-nixos";
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
