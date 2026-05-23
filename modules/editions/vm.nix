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
    pnpm
    # Linting / formatting
    biome
    nil # Nix LSP
    # AI tools — lightweight coding agents (all available in nixpkgs)
    # allowUnfree is already active in modules/core/packages.nix
    claude-code         # Anthropic Claude Code (unfree) — use with OpenRouter
    codex               # OpenAI Codex CLI (Rust) — use with OpenRouter
    github-copilot-cli  # Standalone `copilot` binary (unfree) — copilot auth login
  ];

  # Docker and libvirtd disabled in VM for minimal footprint.
  # lib.mkForce overrides the lib.mkDefault true in virtualisation.nix.
  virtualisation.docker.enable = lib.mkForce false;
  virtualisation.libvirtd.enable = lib.mkForce false;
}
