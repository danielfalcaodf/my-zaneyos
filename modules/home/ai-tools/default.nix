# AI Tools — Home Manager entry point
# Imported from modules/home/editions/default.nix for all editions (including vm).
# Provides: shell env loading, scripts (ai-env-check, ai-tools-list, etc.)
{pkgs, ...}: {
  imports = [
    ./shell.nix
    ./scripts.nix
  ];
}
