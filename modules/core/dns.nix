# DNS local — resolve *.localhost domains via standalone dnsmasq.
# With this, http://portainer.localhost works without editing /etc/hosts.
#
# Uses services.dnsmasq (independent service) instead of NetworkManager's
# built-in dnsmasq, which conflicts with systemd-resolved on modern NixOS.
#
# To verify after rebuild:
#   systemctl status dnsmasq
#   resolvectl status
#   dig portainer.localhost @127.0.0.1
{...}: {
  # Disable systemd-resolved's stub listener so dnsmasq can bind to port 53.
  # DNS forwarding by resolved is still active; only the local stub is disabled.
  services.resolved.settings = {
    Resolve = {
      DNSStubListener = "no";
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      # Resolve all *.localhost to loopback
      address = "/.localhost/127.0.0.1";
    };
  };
}
