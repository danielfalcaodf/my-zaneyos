# AI Tools — Tier 3 (Full edition only)
# Heavy/local AI: inference engines, self-hosted models.
#
# Ollama service is already toggled via services.ollama.enable in full.nix.
# Open WebUI is deployed as a Docker stack (see docker/stacks/).
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # llama.cpp — local LLM inference CLI (CPU + GPU)
    # Usage: llama-cli -m model.gguf -p "prompt"
    llama-cpp
  ];

  # Tabby: self-hosted AI code completion server
  # Uncomment to enable the NixOS service:
  # services.tabby.enable = true;
  # services.tabby.model = "StarCoder-1B";
}
