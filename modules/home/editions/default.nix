# Home Manager edition entrypoint.
# Imported from modules/home/default.nix based on variables.nix `edition`.
# Adds home-level extras (shell integration, desktop entries) per edition.
{host, ...}: let
  vars = import ../../../hosts/${host}/variables.nix;
  edition = vars.edition or "basic";
in {
  imports =
    # AI Tools shell integration + scripts — all editions (vm included)
    [../ai-tools]
    # Dev tools shell integration (NVM, SDKMAN, mise) — all editions except vm
    ++ (
      if edition != "vm"
      then [./dev-tools.nix]
      else []
    );
}
