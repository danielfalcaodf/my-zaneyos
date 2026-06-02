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

  # Ollama — disabled by default, enable manually or via toggle
  # services.ollama.enable = true;

  # Android SDK via QEMU/libvirt already in virtualisation.nix
}
