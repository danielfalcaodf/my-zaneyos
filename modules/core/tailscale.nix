# Tailscale VPN — optional WireGuard-based mesh VPN for remote access.
#
# Enable by setting `tailscaleEnable = true;` in variables.nix.
# After a NixOS rebuild, authenticate by running:
#
#   sudo tailscale up
#
# Or, if you have an auth key (from https://login.tailscale.com/admin/settings/keys):
#
#   sudo tailscale up --authkey=tskey-auth-XXXX
#
# Once connected, remote devices can access homelab services by pointing their
# DNS to the Tailscale IP of this host, or by running a split-DNS configuration.
#
# Future: use `sudo tailscale cert <hostname>` for a valid HTTPS cert via ts.net.
{...}: {
  services.tailscale = {
    enable = true;
    # Open Tailscale's UDP port automatically.
    openFirewall = true;
  };

  # Trust all traffic coming from the Tailscale interface — no port filtering.
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # Advertise local DNS domain via Tailscale split DNS (optional, manual step).
  # See docs/network.md for the full Tailscale + DNS setup guide.
}
