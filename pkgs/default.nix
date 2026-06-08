# pkgs/default.nix — Aggregador de pacotes customizados do ZaneyOS
#
# Este arquivo é importado pelo overlays.nix e expõe todos os pacotes
# das sub-pastas via callPackage.
#
# Como adicionar um novo pacote:
#   1. Execute: zcli pkg scaffold <github-url>
#      Isso cria automaticamente pkgs/<nome>/default.nix
#   2. Adicione a entrada abaixo e rode: zcli rebuild
#
# Exemplo:
#   hermes-agent = pkgs.callPackage ./hermes-agent {};
#
# Referência: https://nixos.org/manual/nixpkgs/stable/#chap-pkgs-callpackage
{pkgs}: {
  # Pacotes customizados — adicionados via `zcli pkg scaffold`
  # Exemplo (descomente após criar o pacote):
  # hermes-agent = pkgs.callPackage ./hermes-agent {};
  # hermes-agent = pkgs.callPackage ./hermes-agent {};
}
