# Medium edition — dev workstation: dev tools, homelab, cloud (no LLM/Android).
# Extends basic with more databases, cloud tools and kubernetes CLI.
{pkgs, ...}: {
  imports = [
    ./basic.nix
    # AI Tools tier 2: opencode, aider, goose-cli, gemini-cli, shell-gpt
    ../ai-tools/tier2.nix
  ];

  environment.systemPackages = with pkgs; [
    # Additional dev tools
    pre-commit
    lefthook
    gitleaks
    zellij
    # Java
    jdk21
    maven
    gradle
    # Database clients
    mysql80  # mysql client
    pspg
    dbeaver-bin
    # Cloud / DevOps
    awscli2
    google-cloud-sdk
    terraform
    terragrunt
    # Kubernetes CLI (no cluster)
    kubectl
    k9s
    helm
    kubectx  # includes kubens
    stern
    kustomize
    # Utilities
    redis
  ];
}
