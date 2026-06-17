# Node.js ecosystem — runtime, pnpm, and global package paths.
# Designed for NixOS read-only filesystem: global installs go to ~/.
{
  pkgs,
  config,
  ...
}: {
  # home.packages = with pkgs; [
  #   nodejs_22
  #   pnpm
  #   # Framework CLIs (installed via nix for reproducibility)
  #   angular-cli
  #   create-react-app
  #   nestjs-cli
  #   ionic-cli
  # ];

  # NPM: redirect global installs to ~/.npm-packages
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-packages
  '';

  # PNPM: store global packages in ~/.local/share/pnpm
  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  # Add both bin directories to PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-packages/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
  ];
}
