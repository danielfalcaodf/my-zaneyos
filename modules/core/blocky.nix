# Blocky DNS proxy — replaces dnsmasq for LAN-wide DNS resolution.
#
# Why Blocky instead of dnsmasq?
#   - Listens on 0.0.0.0:53 so any device on the LAN can use this host as
#     its DNS server (dnsmasq was loopback-only).
#   - Supports DNS-over-HTTPS upstreams (Quad9), ad-blocking, and metrics.
#   - Wildcard custom DNS: *.homelab.lan → lanIP (the LAN IP of this machine).
#
# Router configuration (done once, manually):
#   Set the "Primary DNS" on your router to the LAN IP of this NixOS host.
#   Example: if this PC is 192.168.1.100, set router DNS = 192.168.1.100.
#
# To verify after rebuild:
#   systemctl status blocky
#   dig portainer.homelab.lan @127.0.0.1
#   # From another device on the LAN:
#   dig portainer.homelab.lan @192.168.1.100
{host, ...}: let
  vars = import ../../hosts/${host}/variables.nix;
  localDomain = vars.localDomain or "homelab.lan";
  lanIP = vars.lanIP or "127.0.0.1";
in {
  # Prevent NetworkManager from overwriting /etc/resolv.conf with DHCP-provided
  # DNS servers — without this, NM ignores Blocky and the server itself falls
  # back to 9.9.9.9 (which can't resolve *.homelab.lan).
  networking.networkmanager.dns = "none";

  # Point the system resolver at Blocky on localhost.
  # nameservers writes 127.0.0.1 into /etc/resolv.conf so every process on
  # this machine uses Blocky (and therefore resolves *.homelab.lan correctly).
  networking.nameservers = ["127.0.0.1"];

  # Disable systemd-resolved stub listener so Blocky can bind port 53.
  # systemd-resolved continues to manage the system resolver but forwards
  # all queries to Blocky at 127.0.0.1 instead of its internal stub.
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSStubListener = "no";
        DNS = "127.0.0.1";
        FallbackDNS = "9.9.9.9 1.1.1.1";
        DNSSEC = "false";
      };
    };
  };

  services.blocky = {
    enable = true;
    settings = {
      # Bootstrap DNS: used only to resolve the DoH upstream hostnames.
      bootstrapDns = {
        upstream = "tcp+udp:9.9.9.9";
        ips = ["9.9.9.9" "149.112.112.112"];
      };

      # Upstream DNS resolvers — Quad9 via DNS-over-HTTPS.
      upstreams.groups.default = [
        "https://dns.quad9.net/dns-query"
        "https://dns.cloudflare.com/dns-query"
      ];

      # Custom DNS: resolve *.homelab.lan → LAN IP of this machine.
      # Devices querying this DNS server will be able to reach all services.
      customDNS = {
        filterUnmappedTypes = false;
        mapping = {
          "${localDomain}" = lanIP;
          "*.${localDomain}" = lanIP;
        };
      };

      # Ad/tracker blocking using StevenBlack hosts file.
      blocking = {
        blackLists.ads = [
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        ];
        clientGroupsBlock.default = ["ads"];
      };

      # Listen on all interfaces, port 53 (DNS) and 4000 (HTTP API/metrics).
      ports = {
        dns = 53;
        http = 4000;
      };

      # Prometheus metrics endpoint at http://localhost:4000/metrics
      prometheus.enable = true;

      # Log only queries blocked by blocking rules (reduce noise).
      log = {
        level = "warn";
        format = "text";
      };
    };
  };

  # Allow inbound DNS traffic from the LAN.
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
