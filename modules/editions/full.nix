# Full edition — complete workstation: all dev tools, homelab, cloud, LLM, mobile.
# Extends medium with Ollama, k3d, Android SDK and extra cloud tools.
{pkgs, ...}: {
  imports = [
    ./medium.nix
    # AI Tools tier 3: llama-cpp (Ollama via services.ollama, Open WebUI via Docker)
    ../ai-tools/tier3.nix
  ];

  environment.systemPackages = with pkgs; [
    # Kubernetes extras
    k3d
    # Cloud extras
    firebase-tools
    # LLM / AI
    aichat
    # Utilities
    distrobox
  ];

  # Ollama configuration for LLM (manual model management)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "qwen2.5-coder:7b"
      "llama3.1:8b"
      "nomic-embed-text:v1.5"
    ];
    environmentVariables = {
      OLLAMA_GPU_LAYERS = "99";
      OLLAMA_CONTEXT_SIZE = "8192";
      OLLAMA_NUM_PARALLEL = "2";
      OLLAMA_NUM_THREAD = "12";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_QUANT = "1";
      OLLAMA_GPU_MEMORY_FRACTION = "0.9";
      OLLAMA_KEEP_ALIVE = "24h";
    };
  };

  # llama.cpp and lm-studio configs kept for manual use
  # Android SDK via QEMU/libvirt already in virtualisation.nix

  services.hermes-agent = {
    enable = true;
    settings.model.default = "anthropic/claude-sonnet-4";
    addToSystemPackages = true;
  };
}
