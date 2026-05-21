# Home Manager edition integration — dev tools shell configuration.
# Handles NVM and SDKMAN shell initialization (they are not nix packages,
# they install themselves into ~/.nvm and ~/.sdkman).
#
# Coexistence strategy:
#   - mise: manages global tool versions (default fallback)
#   - NVM:  manages Node.js per-project (takes precedence for Node when active)
#   - SDKMAN: manages Java/JVM per-project (takes precedence for Java/Kotlin when active)
#   - Priority: project .tool-versions (mise) < NVM shell < SDKMAN shell < explicit env
{pkgs, ...}: {
  home.packages = with pkgs; [
    # mise (polyglot version manager — global fallback)
    mise
    # Shell utilities for NVM/SDKMAN integration
    curl
    unzip
    zip
  ];

  # NVM: source NVM if installed (installer puts it at ~/.nvm)
  # Run `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash` to install
  programs.zsh.initExtra = ''
    # NVM (Node Version Manager)
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # SDKMAN (Java/JVM version manager)
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

    # mise (global fallback — activate last so NVM/SDKMAN per-project take precedence)
    eval "$(mise activate zsh)"
  '';

  home.sessionVariables = {
    # mise configuration
    MISE_GLOBAL_TOOL_VERSIONS_FILE = "$HOME/.config/mise/config.toml";
  };
}
