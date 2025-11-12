{
  config,
  inputs,
  system,
  ...
}: {
  services.surrealdb-bin = {
    enable = true;
    #package = inputs.surrealdb.packages.${system}.latest;
    auth = {
      username = "root";
    };
    bind = "0.0.0.0:8000";
  };
  # For nixos-shell compatibility
  users.users.root.initialPassword = "test";
  services.getty.autologinUser = "root";
}
