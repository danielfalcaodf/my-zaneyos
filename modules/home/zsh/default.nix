{
  profile,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./zshrc-personal.nix
  ];

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    autosuggestion.enable = true;
    syntaxHighlighting = {
      enable = true;
      highlighters = ["main" "brackets" "pattern" "regexp" "root" "line"];
    };
    historySubstringSearch.enable = true;

    history = {
      ignoreDups = true;
      save = 10000;
      size = 10000;
    };

    oh-my-zsh = {
      enable = true;
      theme = "spaceship";
      # spaceship-prompt installs theme at share/zsh/themes/spaceship.zsh-theme
      custom = "${pkgs.spaceship-prompt}/share/zsh";
      plugins = [
        "git"
        "jsontools"
        "web-search"
        "command-not-found"
      ];
    };

    plugins = [];

    initContent = ''
      bindkey "\eh" backward-word
      bindkey "\ej" down-line-or-history
      bindkey "\ek" up-line-or-history
      bindkey "\el" forward-word
      if [ -f $HOME/.zshrc-personal ]; then
        source $HOME/.zshrc-personal
      fi

      SPACESHIP_PROMPT_ORDER=(
        time
        user
        dir
        git
        node
        java
        docker
        docker_compose
        azure
        venv
        dotnet
        aws
        gcloud
        exec_time
        line_sep
        jobs
        exit_code
        char
        sudo
        battery
      )
    '';

    shellAliases = {
      nix-fmt-all = "nix fmt ./";
      sv = "sudo nvim";
      v = "nvim";
      c = "clear";
      fr = "nh os switch --hostname ${profile}";
      fu = "nh os switch --hostname ${profile} --update";
      zu = "sh <(curl -L https://gitlab.com/Zaney/zaneyos/-/releases/latest/download/install-zaneyos.sh)";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
      cat = "bat";
      man = "batman";
    };
  };
}
