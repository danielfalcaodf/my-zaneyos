{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.docker-registry-custom;
in {
  options.services.docker-registry-custom = {
    enable = lib.mkEnableOption "Enable Docker Registry (NixOS native, custom wrapper)";

    port = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Internal port for registry";
    };

    storagePath = lib.mkOption {
      type = lib.types.str; # Alterado para string para facilitar o tmpfiles
      default = "/var/lib/docker-registry";
      description = "Path for registry storage (BTRFS nodatacow)";
    };

    auth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable htpasswd authentication";
    };

    htpasswdFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/docker-registry/htpasswd";
      description = "Path to htpasswd file";
    };

    realm = lib.mkOption {
      type = lib.types.str;
      default = "ZaneyOS Registry";
      description = "Authentication realm";
    };

    deleteEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow image deletion";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "Log level (debug, info, warn, error)";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1. Cria o diretório com permissões corretas
    systemd.tmpfiles.rules = [
      "d ${cfg.storagePath} 0750 docker-registry docker-registry - -"
    ];

    # 2. Docker Registry service
    services.dockerRegistry = {
      enable = true;
      port = cfg.port;
      storagePath = cfg.storagePath;
      enableDelete = cfg.deleteEnabled;
      openFirewall = false; # Proxied via Caddy
      extraConfig =
        {
          log.level = cfg.logLevel;
          # Só injeta o bloco auth se cfg.auth for true
        }
        // lib.optionalAttrs cfg.auth {
          auth.htpasswd = {
            realm = cfg.realm;
            path = cfg.htpasswdFile;
          };
        };
    };
  };
}
