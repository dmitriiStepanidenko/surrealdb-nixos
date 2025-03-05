{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.surrealdb-bin;
in {
  options.services.surrealdb-bin = {
    enable = mkEnableOption "SurrealDB database service";

    package = mkOption {
      type = types.package;
      default = pkgs.surrealdb;
      description = "The SurrealDB package to use";
    };

    bind = mkOption {
      type = types.str;
      default = "127.0.0.1:8000";
      description = "The hostname or IP address to listen for connections on";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/surrealdb";
      description = "Directory to store database files";
    };

    log = mkOption {
      type = types.enum ["none" "full" "error" "warn" "info" "debug" "trace"];
      default = "info";
      description = "The logging level for the database";
    };

    auth = {
      username = mkOption {
        type = types.str;
        default = "root";
        description = "The username for the initial database root user";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "File containing the password for the initial database root user";
      };

      unauthenticated = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to allow unauthenticated access";
      };
    };

    strict = mkOption {
      type = types.bool;
      default = false;
      description = "Whether strict mode is enabled on this database instance";
    };

    queryTimeout = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "30s";
      description = "The maximum duration that a set of statements can run for";
    };

    transactionTimeout = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "5s";
      description = "The maximum duration that any single transaction can run for";
    };

    tls = {
      certFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the certificate file for encrypted client connections";
      };

      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the private key file for encrypted client connections";
      };
    };

    capabilities = {
      allowAll = mkOption {
        type = types.bool;
        default = false;
        description = "Allow all capabilities except for those more specifically denied";
      };

      allowScripting = mkOption {
        type = types.bool;
        default = false;
        description = "Allow execution of embedded scripting functions";
      };

      allowGuests = mkOption {
        type = types.bool;
        default = false;
        description = "Allow guest users to execute queries";
      };

      denyAll = mkOption {
        type = types.bool;
        default = false;
        description = "Deny all capabilities except for those more specifically allowed";
      };

      denyScripting = mkOption {
        type = types.bool;
        default = false;
        description = "Deny execution of embedded scripting functions";
      };

      denyGuests = mkOption {
        type = types.bool;
        default = false;
        description = "Deny guest users to execute queries";
      };
    };

    importFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a SurrealQL file that will be imported when starting the server";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.surrealdb = {
      description = "SurrealDB Database Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Restart = "on-failure";
        User = "surrealdb";
        Group = "surrealdb";

        StateDirectory = "surrealdb";
        StateDirectoryMode = "0700";
        WorkingDirectory = cfg.dataDir;
      };
      script = let
        args =
          [
            "start"
            "--log ${cfg.log}"
            "rocksdb://${cfg.dataDir}"
          ]
          ++ (optionals (cfg.auth.passwordFile != null) ["--password" "\"$(cat ${cfg.auth.passwordFile} )\""])
          ++ (optionals cfg.strict ["--strict"])
          ++ (optionals (cfg.queryTimeout != null) ["--query-timeout ${cfg.queryTimeout}"])
          ++ (optionals (cfg.transactionTimeout != null) ["--transaction-timeout ${cfg.transactionTimeout}"])
          ++ (optionals (cfg.tls.certFile != null) ["--web-crt ${cfg.tls.certFile}"])
          ++ (optionals (cfg.tls.keyFile != null) ["--web-key ${cfg.tls.keyFile}"])
          ++ (optionals (cfg.importFile != null) ["--import-file ${cfg.importFile}"])
          ++ (optionals cfg.capabilities.allowAll ["--allow-all"])
          ++ (optionals cfg.capabilities.allowScripting ["--allow-scripting"])
          ++ (optionals cfg.capabilities.allowGuests ["--allow-guests"])
          ++ (optionals cfg.capabilities.denyAll ["--deny-all"])
          ++ (optionals cfg.capabilities.denyScripting ["--deny-scripting"])
          ++ (optionals cfg.capabilities.denyGuests ["--deny-guests"]);
      in "${cfg.package}/bin/surreal ${concatStringsSep " " args}";

      environment = {
        SURREAL_USER = cfg.auth.username;
        SURREAL_UNAUTHENTICATED = boolToString cfg.auth.unauthenticated;
        SURREAL_BIND = cfg.bind;
      };
    };

    users.users.surrealdb = {
      isSystemUser = true;
      group = "surrealdb";
      home = cfg.dataDir;
      createHome = true;
      description = "SurrealDB service user";
    };

    users.groups.surrealdb = {};
  };
}
