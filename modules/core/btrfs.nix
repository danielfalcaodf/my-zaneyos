# BTRFS Configuration for Docker Volumes
# Creates subvolumes with nodatacow (No Copy-on-Write) for database volumes
# to avoid performance degradation and excessive disk wear on BTRFS.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.btrfs.docker;
in {
  options = {
    btrfs = {
      docker = {
        enable = lib.mkEnableOption "Enable BTRFS subvolumes for Docker volumes";

        # Parent subvolume path (where docker subvolumes will be created)
        parentPath = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/docker";
          description = "Parent path for Docker BTRFS subvolumes";
        };

        # Subvolumes to create with nodatacow.
        # Docker Compose nomeia volumes como "<project>_<volume>" onde <project>
        # é o nome da pasta do compose (ou o nome definido em `name:` na top-level).
        # Os caminhos abaixo cobrem ambos os padrões:
        #   - nome direto (ex: postgres_data) → quando o nome do projeto docker é "docker"
        #   - prefixado (ex: databases_postgres_data) → quando o compose está em databases/
        subvolumes = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default =
            # Volumes sem prefixo (caso o nome do projeto Docker seja "docker" ou vazio)
            {
              postgres = { mountPoint = "/var/lib/docker/volumes/postgres_data"; };
              mysql = { mountPoint = "/var/lib/docker/volumes/mysql_data"; };
              redis = { mountPoint = "/var/lib/docker/volumes/redis_data"; };
              sqlserver = { mountPoint = "/var/lib/docker/volumes/sqlserver_data"; };
              grafana = { mountPoint = "/var/lib/docker/volumes/grafana_data"; };
              loki = { mountPoint = "/var/lib/docker/volumes/loki_data"; };
              prometheus = { mountPoint = "/var/lib/docker/volumes/prometheus_data"; };
              portainer = { mountPoint = "/var/lib/docker/volumes/portainer_data"; };
              caddy = { mountPoint = "/var/lib/docker/volumes/caddy_data"; };
              caddy_config = { mountPoint = "/var/lib/docker/volumes/caddy_config"; };
              openwebui = { mountPoint = "/var/lib/docker/volumes/open_webui_data"; };
              cloudbeaver = { mountPoint = "/var/lib/docker/volumes/cloudbeaver_data"; };
              minio = { mountPoint = "/var/lib/docker/volumes/minio_data"; };
            }
            # Volumes com prefixos de pasta (zstack roda compose dentro da pasta da categoria,
            # então o Docker Compose usa o nome da pasta como prefixo do projeto)
            // {
              databases_postgres = { mountPoint = "/var/lib/docker/volumes/databases_postgres_data"; };
              databases_mysql = { mountPoint = "/var/lib/docker/volumes/databases_mysql_data"; };
              databases_redis = { mountPoint = "/var/lib/docker/volumes/databases_redis_data"; };
              databases_sqlserver = { mountPoint = "/var/lib/docker/volumes/databases_sqlserver_data"; };
              databases_cloudbeaver = { mountPoint = "/var/lib/docker/volumes/databases_cloudbeaver_data"; };
            }
            // {
              monitoring_grafana = { mountPoint = "/var/lib/docker/volumes/monitoring_grafana_data"; };
              monitoring_loki = { mountPoint = "/var/lib/docker/volumes/monitoring_loki_data"; };
              monitoring_prometheus = { mountPoint = "/var/lib/docker/volumes/monitoring_prometheus_data"; };
            }
            // {
              homelab_caddy = { mountPoint = "/var/lib/docker/volumes/homelab_caddy_data"; };
              homelab_caddy_config = { mountPoint = "/var/lib/docker/volumes/homelab_caddy_config"; };
            }
            // {
              automation_portainer = { mountPoint = "/var/lib/docker/volumes/automation_portainer_data"; };
            }
            // {
              ai_openwebui = { mountPoint = "/var/lib/docker/volumes/ai_open_webui_data"; };
            }
            // {
              storage_minio = { mountPoint = "/var/lib/docker/volumes/storage_minio_data"; };
            }
            // {
              caddy_caddy = { mountPoint = "/var/lib/docker/volumes/caddy_caddy_data"; };
              caddy_caddy_config = { mountPoint = "/var/lib/docker/volumes/caddy_caddy_config"; };
            }
            // {
              portainer_portainer = { mountPoint = "/var/lib/docker/volumes/portainer_portainer_data"; };
            }
            // {
              homelab_portainer = { mountPoint = "/var/lib/docker/volumes/homelab_portainer_data"; };
              homelab_technitium_dns = { mountPoint = "/var/lib/docker/volumes/homelab_technitium_dns_data"; };
            }
            // {
              automation_mailpit = { mountPoint = "/var/lib/docker/volumes/automation_mailpit_data"; };
              automation_n8n = { mountPoint = "/var/lib/docker/volumes/automation_n8n_data"; };
              automation_uptime_kuma = { mountPoint = "/var/lib/docker/volumes/automation_uptime_kuma_data"; };
              automation_woodpecker = { mountPoint = "/var/lib/docker/volumes/automation_woodpecker-server-data"; };
            }
            // {
              llm_openwebui = { mountPoint = "/var/lib/docker/volumes/llm_open_webui_data"; };
            };
          description = "Docker volume subvolumes with nodatacow. Keys are volume names (prefix reflects Docker Compose project prefix from folder name).";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Criar subvolumes BTRFS e aplicar nodatacow para volumes Docker
    systemd.services.btrfs-docker-subvolumes = {
      description = "Create BTRFS subvolumes for Docker volumes with nodatacow";
      wantedBy = ["multi-user.target"];
      before = ["docker.service"];
      after = ["local-fs.target"];
      requires = ["local-fs.target"];
      path = [ pkgs.btrfs-progs pkgs.coreutils pkgs.gawk pkgs.utillinux pkgs.e2fsprogs ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "btrfs-docker-subvolumes" ''
          set -e

          PARENT="${cfg.parentPath}"

          # Esperar até que o path pai exista (pode ser bind mount do NixOS docker module)
          for i in $(seq 1 30); do
            if [ -d "$PARENT" ]; then
              break
            fi
            echo "Waiting for $PARENT to exist (attempt $i/30)..."
            sleep 1
          done

          if [ ! -d "$PARENT" ]; then
            echo "WARNING: $PARENT does not exist after 30s. Skipping."
            exit 0
          fi

          # Verificar que $PARENT está num filesystem BTRFS
          FS_TYPE=$(df -T "$PARENT" 2>/dev/null | tail -1 | awk '{print $2}')
          if [ "$FS_TYPE" != "btrfs" ]; then
            echo "WARNING: $PARENT is on $FS_TYPE, not BTRFS. Skipping subvolume creation."
            exit 0
          fi

          # Criar cada subvolume BTRFS com nodatacow
          ${lib.concatMapStrings (name: let
            mountPoint = cfg.subvolumes.${name}.mountPoint;
          in ''
            SUBVOL="${mountPoint}"
            if btrfs subvolume show "$SUBVOL" >/dev/null 2>&1; then
              echo "BTRFS subvolume already exists: $SUBVOL"
              chattr +C "$SUBVOL" 2>/dev/null || true
            elif [ -d "$SUBVOL" ]; then
              # Diretório comum existe mas não é subvolume — pode ter dados do Docker.
              # Aplicar nodatacow no diretório e avisar em vez de remover.
              echo "WARNING: $SUBVOL exists as a regular directory (not a BTRFS subvolume)."
              echo "  Applying nodatacow to existing directory. If Docker has data here, it is preserved."
              chattr +C "$SUBVOL" 2>/dev/null || true
            else
              echo "Creating BTRFS subvolume: $SUBVOL"
              btrfs subvolume create "$SUBVOL"
              chattr +C "$SUBVOL"
              echo "Created $SUBVOL with nodatacow"
            fi
          '') (lib.attrNames cfg.subvolumes)}

          echo "BTRFS Docker subvolumes ready."
        '';
      };
    };

    # Garantir que o diretório pai exista (os subvolumes são criados pelo serviço acima)
    systemd.tmpfiles.rules = [ "d ${cfg.parentPath} 0755 root root - -" ];

    virtualisation.docker.storageDriver = "btrfs";
  };
}