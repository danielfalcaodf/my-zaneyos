# DNS local — resolve *.localhost domains via NetworkManager + dnsmasq.
# With this, http://portainer.localhost works without editing /etc/hosts.
# Uses the existing NetworkManager already enabled in network.nix.
{...}: {
  networking.networkmanager.dns = "dnsmasq";

  # dnsmasq: resolve all *.localhost to loopback
  environment.etc."NetworkManager/dnsmasq.d/localhost.conf".text = ''
    address=/.localhost/127.0.0.1
  '';
}
