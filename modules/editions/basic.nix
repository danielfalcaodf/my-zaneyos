# Basic edition — light desktop: VS Code, Docker, Portainer, Caddy, essential dev tools.
{pkgs, ...}: {
  imports = [
    # Caddy HTTPS reverse proxy (portainer.homelab.lan, db.homelab.lan, etc.)
    ../core/caddy.nix
    # Blocky DNS proxy — LAN-wide DNS with wildcard *.homelab.lan resolution
    ../core/blocky.nix
    # AI Tools tier 1: claude-code, codex, qwen-code, mods
    ../ai-tools/tier1.nix
  ];
  environment.systemPackages = with pkgs; [
    # Dev essentials
    git
    lazygit
    gh
    delta
    just
    direnv
    mise
    # Node ecosystem
    nodejs_22
    pnpm
    # Python
    python3
    uv
    ruff
    # Database clients
    postgresql
    # LSPs
    nil
    typescript-language-server
    bash-language-server
    yaml-language-server
    python3Packages.python-lsp-server
    biome
    # Utilities
    duf
    ncdu
    jq
    yq-go
  ];

  # Docker enabled for Basic
  virtualisation.docker.enable = true;
}
