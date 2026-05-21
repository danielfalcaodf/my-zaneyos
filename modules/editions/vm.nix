# VM edition — minimal, lightweight, no heavy services.
# Plymouth is already disabled in boot.nix when edition == "vm".
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Minimal dev tools only
    git
    curl
    wget
    htop
    ripgrep
    fd
    jq
  ];

  # Docker optional in VM (disabled by default for minimal footprint)
  virtualisation.docker.enable = false;
  virtualisation.libvirtd.enable = false;
}
