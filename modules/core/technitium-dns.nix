# Technitium DNS Server — Modern DNS Server with Web UI
# Provides GUI for managing local DNS zones, conditional forwarding, DNS-over-HTTPS, etc.
# Alternative to Blocky with web interface for DNS management.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.technitium-dns;
in {
  options.services.technitium-dns = {
    enable = lib.mkEnableOption "Enable Technitium DNS Server";

    # Web UI port (internal, proxied via Caddy)
    httpPort = lib.mkOption {
      type = lib.types.int;
      default = 5380;
      description = "HTTP port for Web UI";
    };

    # DNS port
    dnsPort = lib.mkOption {
      type = lib.types.int;
      default = 53;
      description = "DNS port (53 requires root/CAP_NET_BIND_SERVICE)";
    };

    # Data directory (persistent storage)
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/technitium-dns";
      description = "Data directory for zones and config";
    };

    # Admin password (from secrets)
    adminPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Admin password for Web UI (set via secrets)";
    };

    # Enable DNS-over-HTTPS
    dohEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DNS-over-HTTPS endpoint";
    };

    # Upstream DNS servers
    upstreams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["9.9.9.9" "1.1.1.1"];
      description = "Upstream DNS servers";
    };

    # Local domain configuration
    localDomain = lib.mkOption {
      type = lib.types.str;
      default = "homelab.lan";
      description = "Local domain for wildcard DNS";
    };

    # LAN IP for wildcard resolution
    lanIP = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "LAN IP for *.localDomain resolution";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create data directory with BTRFS nodatacow
    systemd.tmpfiles.rules = [
      {
        path = cfg.dataDir;
        type = "d";
        mode = "0755";
        user = "root";
        group = "root";
        argument = "!/bin/bash -c 'if [ ! -d \"${cfg.dataDir}\" ]; then btrfs subvolume create -o nodatacow \"${cfg.dataDir}\"; fi'";
      }
    ];

    # Technitium DNS via Docker (no native NixOS package yet)
    virtualisation.docker.enable = true;

    # Docker Compose for Technitium (will be added to homelab stack)
    # Configuration is managed via environment variables and config file

    # Firewall rules
    networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.dnsPort];
    networking.firewall.allowedUDPPorts = [cfg.dnsPort];

    # Caddy proxy for Web UI (HTTPS)
    # This will be added to caddy.nix when enabled
  };
}