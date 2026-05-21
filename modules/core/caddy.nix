# Caddy reverse proxy — local-only reverse proxy for homelab services.
# Serves .localhost domains via HTTP (no TLS needed for loopback).
# Each service gets a subdomain: portainer.localhost, db.localhost, etc.
# This module is imported by non-vm editions via modules/editions/*.nix.
{...}: {
  services.caddy = {
    enable = true;
    # Global options: disable HTTPS for .localhost domains (loopback only)
    globalConfig = ''
      auto_https off
    '';
    # Virtual hosts — each proxies to a Docker stack bound on 127.0.0.1
    virtualHosts = {
      "portainer.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:9000
        '';
      };
      "db.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8082
        '';
      };
      "cloudbeaver.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8978
        '';
      };
      "n8n.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:5678
        '';
      };
      "uptime.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3001
        '';
      };
      "mail.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8025
        '';
      };
      "minio.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:9001
        '';
      };
      "grafana.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3000
        '';
      };
      "home.localhost" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3003
        '';
      };
    };
  };

  # Open port 80 for local Caddy access (no 443 needed for .localhost)
  networking.firewall.allowedTCPPorts = [80];
}
