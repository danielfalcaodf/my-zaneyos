# AI Tools — Shell Integration (Home Manager)
# Loads ~/.config/ai-tools/openrouter.env if present.
# Never sources files that contain secrets from /nix/store.
# The env file lives outside the repo and is NOT managed by Nix.
{...}: {
  # zsh: load OpenRouter env file if present (primary shell)
  programs.zsh.initContent = ''
    # AI Tools — OpenRouter environment
    if [ -f "$HOME/.config/ai-tools/openrouter.env" ]; then
      source "$HOME/.config/ai-tools/openrouter.env"
    fi
  '';

  # fish: equivalent sourcing (fish syntax)
  programs.fish.interactiveShellInit = ''
    # AI Tools — OpenRouter environment
    if test -f "$HOME/.config/ai-tools/openrouter.env"
      bass source "$HOME/.config/ai-tools/openrouter.env" 2>/dev/null; or true
    end
  '';

  # bash: write a sourcing helper that bash users can load from ~/.bashrc
  # Since programs.bash.enable = false in bash.nix, we write the file directly.
  # Users can add to their .bashrc:
  #   [ -f ~/.config/ai-tools/bash-env.sh ] && source ~/.config/ai-tools/bash-env.sh
  # Or uncomment the block in ~/.bashrc-personal (managed by bashrc-personal.nix).
  home.file.".config/ai-tools/bash-env.sh" = {
    force = false;
    text = ''
      # AI Tools — OpenRouter environment (bash)
      # Source this file from ~/.bashrc or ~/.bash_profile:
      #   [ -f ~/.config/ai-tools/bash-env.sh ] && source ~/.config/ai-tools/bash-env.sh
      if [ -f "$HOME/.config/ai-tools/openrouter.env" ]; then
        . "$HOME/.config/ai-tools/openrouter.env"
      fi
    '';
  };

  # Codex CLI provider config — no API key, key comes from env file.
  # This is the OpenAI Codex Rust CLI (openai/codex v0.133+).
  # Users can override by editing ~/.codex/config.toml after first build.
  home.file.".codex/config.toml" = {
    force = false; # do not overwrite if user has customised it
    text = ''
      model_provider = "openrouter"
      model = "~anthropic/claude-sonnet-latest"

      [model_providers.openrouter]
      name = "openrouter"
      base_url = "https://openrouter.ai/api/v1"
      env_key = "OPENROUTER_API_KEY"
    '';
  };

  # Hermes config (tool installed manually — see docs/ai-tools.md TODO)
  # ~/.hermes/config.yaml — no API key; key goes in ~/.hermes/.env (not git)
  home.file.".hermes/config.yaml" = {
    force = false;
    text = ''
      model:
        provider: openrouter
        default: ~anthropic/claude-sonnet-latest
    '';
  };
}
