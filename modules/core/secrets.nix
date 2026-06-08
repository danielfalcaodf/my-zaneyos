# Secrets Management with sops-nix
# Generates secrets from encrypted .sops.yaml files into /run/secrets/
# Also generates Docker .env files from secrets for stack deployment.
{
  config,
  lib,
  pkgs,
  inputs,
  username
  ...
}: let
  cfg = config.secrets;
  dockerStacks = config.docker.stacks;
in {
  options = {
    secrets = {
      enable = lib.mkEnableOption "Enable sops-nix secrets management";

      # Path to the sops configuration file
      sopsFile = lib.mkOption {
        type = lib.types.path;
        default = ./secrets.yaml;
        description = "Path to sops.yaml configuration file";
      };

      # Age key file for decryption (optional, can use SSH keys)
      ageKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to age private key file";
      };

      # Secrets to generate for Docker stacks
      docker = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = { };
        description = "Docker stack secrets: { stackName = { secretName = \"secretValue\"; }; }";
      };
    };

    docker.stacks = {
      enable = lib.mkEnableOption "Enable Docker stacks management";

      # Root directory for docker stacks
      rootDir = lib.mkOption {
        type = lib.types.path;
        default = "/home/${username}/zaneyos/docker/stacks";
        description = "Root directory containing docker stack categories";
      };

      # Generate .env files from secrets
      generateEnvFiles = lib.mkEnableOption "Generate .env files from sops-nix secrets";

      # Custom ports for databases to avoid conflicts with dev databases
      ports = lib.mkOption {
        type = lib.types.attrsOf lib.types.int;
        default = {
          postgres = 5433;
          mysql = 3307;
          redis = 6380;
          sqlserver = 1434;
          adminer = 8083;
          cloudbeaver = 8979;
        };
        description = "Custom ports for database services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # sops-nix configuration
    sops = {
      enable = true;
      defaultSopsFile = cfg.sopsFile;
      age.keyFile = lib.mkIf (cfg.ageKeyFile != null) cfg.ageKeyFile;
      secrets = lib.mapAttrs (name: value: {
        file = "/run/secrets/${name}";
        owner = "root";
        group = "root";
        mode = "0400";
      }) cfg.docker;
    };

    # Generate Docker .env files from secrets
    systemd.tmpfiles.rules = lib.mkIf dockerStacks.generateEnvFiles [
      {
        path = "${dockerStacks.rootDir}/databases/postgres/.env";
        mode = "0600";
        user = "${username}";
        group = "docker";
        content = lib.mkForce ''
          POSTGRES_USER=postgres
          POSTGRES_PASSWORD=${cfg.docker.postgres.POSTGRES_PASSWORD}
          POSTGRES_DB=devdb
          POSTGRES_PORT=${toString dockerStacks.ports.postgres}
        '';
      }
      {
        path = "${dockerStacks.rootDir}/databases/mysql/.env";
        mode = "0600";
        user = "${username}";
        group = "docker";
        content = lib.mkForce ''
          MYSQL_ROOT_PASSWORD=${cfg.docker.mysql.MYSQL_ROOT_PASSWORD}
          MYSQL_USER=dev
          MYSQL_PASSWORD=${cfg.docker.mysql.MYSQL_PASSWORD}
          MYSQL_DATABASE=devdb
          MYSQL_PORT=${toString dockerStacks.ports.mysql}
        '';
      }
      {
        path = "${dockerStacks.rootDir}/databases/redis/.env";
        mode = "0600";
        user = "${username}";
        group = "docker";
        content = lib.mkForce ''
          REDIS_PASSWORD=${cfg.docker.redis.REDIS_PASSWORD}
        '';
      }
      {
        path = "${dockerStacks.rootDir}/databases/sqlserver/.env";
        mode = "0600";
        user = "${username}";
        group = "docker";
        content = lib.mkForce ''
          MSSQL_SA_PASSWORD=${cfg.docker.sqlserver.MSSQL_SA_PASSWORD}
          MSSQL_PID=Developer
        '';
      }
    ];

    # Ensure docker group exists and user is member
    users.groups.docker = {
      ensureExists = true;
      members = [ "${username}" ];
    };

    # Generate docker-registry htpasswd from secrets
    systemd.tmpfiles.rules = lib.mkIf (config.services.docker-registry.enable && config.services.docker-registry.auth) [
      {
        path = "/run/secrets/docker-registry/htpasswd";
        mode = "0600";
        user = "root";
        group = "root";
        content = lib.mkForce config.secrets.docker.registry.htpasswd or "";
      }
    ];
  };
}