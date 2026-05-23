# AI Tools — Tier 3 (Full edition only)
# Heavy/local AI: inference engines, self-hosted models, desktop apps.
#
# Ollama service is already toggled via services.ollama.enable in full.nix.
# Open WebUI is deployed as a Docker stack (see docker/stacks/).
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # llama.cpp — local LLM inference CLI (CPU + GPU)
    # Usage: llama-cli -m model.gguf -p "prompt"
    llama-cpp

    # TODO: opencode-desktop — Desktop GUI for OpenCode AI coding assistant
    # Package not yet available in nixpkgs unstable (checked 2026-05).
    # Track availability at: https://search.nixos.org/packages?query=opencode-desktop
    # When available, uncomment the line below:
    # opencode-desktop
    #
    # Referência: https://opencode.ai / https://github.com/anomalyco/opencode
    # Edição: full (opencode CLI já está em tier2/medium)
  ];

  # Tabby: self-hosted AI code completion server
  # Uncomment to enable the NixOS service:
  # services.tabby.enable = true;
  # services.tabby.model = "StarCoder-1B";
}
