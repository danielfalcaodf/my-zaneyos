# VM edition — minimal, lightweight, no heavy services.
# Plymouth is already disabled in boot.nix when edition == "vm".
{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Core dev tools — available even on minimal VMs
    git
    curl
    wget
    htop
    ripgrep
    fd
    jq
    # Node ecosystem (documented as available in all editions)
    nodejs_22
    nodePackages.pnpm
    # Linting / formatting
    biome
    nil # Nix LSP
  ];

  # Docker and libvirtd disabled in VM for minimal footprint.
  # lib.mkForce overrides the lib.mkDefault true in virtualisation.nix.
  virtualisation.docker.enable = lib.mkForce false;
  virtualisation.libvirtd.enable = lib.mkForce false;
}
