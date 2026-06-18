{
  pkgs,
  lib,
  host,
  ...
}: let
  # Extensions not in nixpkgs — defined as empty lists (install via VSCode Marketplace)
  hyprlangExts = [];
  hyprlsExts = [];
  neroHyprlandExts = [];
  codeRunnerExts = [];

  # Default settings path in the Nix store (committed, always available).
  # Host-specific override is checked at runtime in home.activation because
  # hosts/<host>/vscode-settings.json is not git-tracked and therefore not
  # present in the Nix store at eval time (builtins.pathExists would always fail).
  defaultSettingsFile = ./vscode-settings.json;
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
      };
    };
  };

  # Copy settings.json on each rebuild (not a symlink — keeps the file editable
  # in VSCode between rebuilds). Use `zcli rebuild` sync prompt to save edits back.
  #
  # Host-specific file is detected at runtime so untracked files in hosts/ are found.
  # The .backup file is always removed to prevent HM backup-conflict failures.
  # Skip flag (~/.cache/zaneyos/vscode-settings-skip) is consumed once per rebuild.
  home.activation.vscodeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_DEST="$HOME/.config/Code/User/settings.json"
    SKIP_FLAG="$HOME/.cache/zaneyos/vscode-settings-skip"
    HOST_SETTINGS="$HOME/zaneyos/hosts/${host}/vscode-settings.json"

    # Always remove the .backup so HM can create it on the next rebuild without conflict.
    ${pkgs.coreutils}/bin/rm -f "$SETTINGS_DEST.backup"

    if [ -f "$SKIP_FLAG" ]; then
      ${pkgs.coreutils}/bin/rm -f "$SKIP_FLAG"
      echo "VSCode settings: skipped for this rebuild (user requested)"
    else
      # Remove any existing file or symlink before copying (handles HM-managed symlinks).
      ${pkgs.coreutils}/bin/rm -f "$SETTINGS_DEST"
      ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$SETTINGS_DEST")"

      if [ -f "$HOST_SETTINGS" ]; then
        ${pkgs.coreutils}/bin/cp "$HOST_SETTINGS" "$SETTINGS_DEST"
      else
        ${pkgs.coreutils}/bin/cp "${defaultSettingsFile}" "$SETTINGS_DEST"
      fi
      ${pkgs.coreutils}/bin/chmod 644 "$SETTINGS_DEST"
    fi
  '';

  home.packages = with pkgs; [
    libsecret
    seahorse
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = ["openssl-1.1.1w"];
}
