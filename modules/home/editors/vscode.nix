{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.lib) attrByPath;

  # Extensions not in nixpkgs — defined as empty lists (install via VSCode Marketplace)
  hyprlangExts = [];
  hyprlsExts = [];
  neroHyprlandExts = [];
  codeRunnerExts = [];
in {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles = {
      default = {
        extensions =
          (with pkgs.vscode-extensions; [
            catppuccin.catppuccin-vsc
            bbenoist.nix
            kamadorueda.alejandra
            jeff-hykin.better-nix-syntax
            ms-vscode.cpptools-extension-pack

            mads-hartmann.bash-ide-vscode
            tamasfe.even-better-toml
            zainchen.json
            shd101wyy.markdown-preview-enhanced
            # Dev essentials
            ms-python.python
            ms-python.vscode-pylance
            ms-azuretools.vscode-docker
            dbaeumer.vscode-eslint
            esbenp.prettier-vscode
            redhat.vscode-yaml
            eamodio.gitlens
            mkhl.direnv
            editorconfig.editorconfig
          ])
          ++ hyprlangExts
          ++ hyprlsExts
          ++ neroHyprlandExts
          ++ codeRunnerExts;

        # FOI REMOVIDO DAQUI O: userSettings = lib.mkDefault baseSettings;
        # Agora o Home Manager não vai mais sequestrar o settings.json.
        # O VSCode Settings Sync poderá criar e modificar esse arquivo livremente!
      };
    };
  };

  # Mantém o suporte para o armazenamento do Token do Sync
  home.packages = with pkgs; [
    libsecret
    seahorse
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = ["openssl-1.1.1w"];
}
