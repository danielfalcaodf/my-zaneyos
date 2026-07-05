# Caddy reverse proxy — HTTPS reverse proxy for homelab services.
#
# Services are available at https://<service>.<localDomain> from any device
# on the LAN (or via Tailscale VPN for remote access).
#
# TLS strategy: Caddy's built-in CA ("local_certs")
#   - Caddy acts as its own certificate authority.
#   - Certs are generated automatically at first start — no external tools needed.
#   - Root CA cert location:
#       /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
#   - Install the root CA once per device (see docs/network.md for instructions).
#   - CA and certs are renewed automatically by Caddy.
#
# This module is imported by non-vm editions via modules/editions/*.nix.
{host, ...}: let
  vars = import ../../hosts/${host}/variables.nix;
  domain = vars.localDomain or "homelab.lan";
  mkProxy = port: {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };
in {
  services.caddy = {
    enable = true;
    # Use Caddy's internal CA for all virtual hosts (no Let's Encrypt needed).
    # Each virtualhost gets a cert signed by the local root CA automatically.
    globalConfig = ''
      local_certs
    '';
    virtualHosts = {
      # ── Homelab ────────────────────────────────────────────────────
      "home.${domain}" = mkProxy 3003;
      "portainer.${domain}" = mkProxy 9000;
      # ── Bancos ─────────────────────────────────────────────────────
      "db.${domain}" = mkProxy 8083;
      "cloudbeaver.${domain}" = mkProxy 8979;
      # ── Monitoring ─────────────────────────────────────────────────
      "grafana.${domain}" = mkProxy 3000;
      "prometheus.${domain}" = mkProxy 9090;
      # ── Automação ──────────────────────────────────────────────────
      "n8n.${domain}" = mkProxy 5678;
      "uptime.${domain}" = mkProxy 3001;
      "mail.${domain}" = mkProxy 8025;
      "woodpecker.${domain}" = mkProxy 8000;
      # ── Storage ────────────────────────────────────────────────────
      "minio.${domain}" = mkProxy 9001;
      # ── Registry ───────────────────────────────────────────────────
      "registry.${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:5000 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      # ── DNS Management ─────────────────────────────────────────────
      "dns.${domain}" = mkProxy 5380;
      # ── LLM / IA ───────────────────────────────────────────────────
      "openwebui.${domain}" = mkProxy 8080;
      "sandbox.${domain}" = mkProxy 8090;
    };
  };

  # Caddy serves HTTPS on 443 and HTTP on 80 (auto-redirect to HTTPS).
  # Port 80 is also open in network.nix; 443 is listed here for clarity.
  networking.firewall.allowedTCPPorts = [80 443];
}
