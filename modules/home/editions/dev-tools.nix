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
    # Cloud CLIs
    awscli2
    google-cloud-sdk
  ];

  # NVM: source NVM if installed (installer puts it at ~/.nvm)
  # Run `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash` to install
  programs.zsh.initContent = ''
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

  # Fish shell: NVM and SDKMAN don't natively support fish.
  # Set env vars so project tooling can locate them; use mise for runtime management.
  # To use NVM in fish, install the fish-nvm wrapper manually:
  #   fisher install jorgebucaran/nvm.fish
  programs.fish.interactiveShellInit = ''
    # NVM — set dir so nvm.fish plugin can find it if installed
    set -x NVM_DIR "$HOME/.nvm"

    # SDKMAN — set dir; use `sdk` commands via `bass` if installed
    set -x SDKMAN_DIR "$HOME/.sdkman"

    # mise (native fish support — manages global tool versions)
    if command -q mise
      mise activate fish | source
    end
  '';

  home.sessionVariables = {
    # mise configuration
    MISE_GLOBAL_TOOL_VERSIONS_FILE = "$HOME/.config/mise/config.toml";
  };
}
