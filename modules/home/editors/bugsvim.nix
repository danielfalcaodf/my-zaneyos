{
  config,
  pkgs,
  lib,
  ...
}: let
  # Local bugsvim config directory bundled in this repo
  bugsvimSrc = ./bugsvim-nvim;
in {
  # Disable HM's Neovim module so it doesn't generate ~/.config/nvim/*
  programs.neovim = lib.mkForce {
    enable = false;
  };

  # Install Neovim + required tools so lazy.nvim can manage plugins/config
  home.packages = with pkgs; [
    neovim

    # Language Servers
    lua-language-server
    pyright
    nodePackages.typescript-language-server
    tailwindcss-language-server
    clang-tools
    nodePackages.bash-language-server
    rust-analyzer
    nodePackages.vscode-langservers-extracted # html, css, json, eslint
    nil # Nix LSP
    hyprls

    # Formatters
    stylua
    ruff
    prettierd
    shfmt
    alejandra

    # Linters
    nodePackages.eslint_d
    luajitPackages.luacheck
    cpplint

    # Additional tools
    ripgrep
    fd
    tree-sitter
    git
    gnumake
  ];

  # Ensure writable config and clear HM symlink remnants during transitions
  home.activation.bugsvimSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    UNDO_DIR="$HOME/.local/share/nvim/undodir"
    if [ ! -d "$UNDO_DIR" ]; then
      $DRY_RUN_CMD mkdir -p "$UNDO_DIR"
      echo "Created NeoVim undo directory at $UNDO_DIR"
    fi

    # Remove HM symlink remnants from nixvim/nvf (if present)
    if [ -L "$HOME/.local/share/nvim/lua" ]; then
      $DRY_RUN_CMD rm -rf "$HOME/.local/share/nvim/lua"
    fi

    # Copy bugsvim config into ~/.config/nvim (writable) so lazy.nvim can manage updates
    SRC=${bugsvimSrc}
    DEST="$HOME/.config/nvim"
    $DRY_RUN_CMD rm -rf "$DEST"
    $DRY_RUN_CMD mkdir -p "$DEST"
    $DRY_RUN_CMD cp -r "$SRC"/. "$DEST"/
    $DRY_RUN_CMD chmod -R u+rwX "$DEST"

    # Lazy.nvim will self-bootstrap on first nvim run
    # The init.lua handles automatic cloning if lazy.nvim is not present
  '';
}
