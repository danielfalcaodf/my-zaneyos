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

    # opencode-desktop — Desktop GUI for OpenCode AI coding assistant
    # https://opencode.ai / https://search.nixos.org/packages?query=opencode-desktop
    # opencode CLI já está em tier2/medium; aqui entra a UI desktop (full only)
    opencode-desktop
  ];

  # Tabby: self-hosted AI code completion server
  # Uncomment to enable the NixOS service:
  # services.tabby.enable = true;
  # services.tabby.model = "StarCoder-1B";
}
