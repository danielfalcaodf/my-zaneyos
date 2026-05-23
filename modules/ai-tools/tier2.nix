# AI Tools — Tier 2 (Medium edition and above)
# Full workstation AI agents: multi-model, cloud-native, team-ready.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # OpenCode — terminal AI coding agent with LSP integration
    # Config: /connect → OpenRouter  (see docs/ai-tools-openrouter.md)
    opencode

    # Aider — AI pair programming in your terminal
    # Usage: aider --model openrouter/anthropic/claude-sonnet-4-5
    aider-chat

    # Goose — Block's autonomous AI developer agent
    # Usage: goose session  /  goose run --with-extension ...
    goose-cli

    # Gemini CLI — Google Gemini in the terminal (1M token context)
    # Usage: gemini  /  gemini -p "explain this codebase"
    gemini-cli

    # shell-gpt — ChatGPT-style prompts in the shell (supports OpenRouter)
    # Usage: sgpt "write a bash one-liner to..." / sgpt --shell "find large files"
    shell-gpt
  ];
}
