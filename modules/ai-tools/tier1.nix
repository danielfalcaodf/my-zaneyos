# AI Tools — Tier 1 (Basic edition and above)
# Lightweight coding agents and CLI tools available from nixpkgs.
# All packages verified in nixpkgs unstable (2025).
#
# GitHub Copilot CLI — available in nixpkgs as `github-copilot-cli` (v1.0.26)
#   Installs standalone binary `copilot` (NOT a gh extension).
#   Authentication: copilot auth login
#   Docs: https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli
#
# TODO: hermes-agent (Nous Research Hermes Agent)
#   Not available in nixpkgs. Check official repo for install method:
#     https://github.com/NousResearch/hermes-agent
#   Once installed: hermes model  → select OpenRouter
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Claude Code — Anthropic's agentic AI coding tool (unfree)
    # Config: set ANTHROPIC_BASE_URL + ANTHROPIC_AUTH_TOKEN for OpenRouter
    claude-code

    # Codex CLI — OpenAI's coding agent (Rust, multi-provider)
    # Config: ~/.codex/config.toml  (see docs/ai-tools-openrouter.md)
    codex

    # GitHub Copilot CLI — standalone `copilot` binary (unfree)
    # Auth: copilot auth login
    # Usage: copilot suggest "..." / copilot explain "..."
    github-copilot-cli

    # Qwen Code — Alibaba Qwen-based coding agent
    # Config: uses OPENROUTER_API_KEY env variable
    qwen-code

    # mods — AI on the command line (charm.sh, pipe-friendly)
    # Usage: echo "explain this" | mods  /  git diff | mods "write commit msg"
    mods
  ];
}
