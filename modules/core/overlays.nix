{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default
    # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
    (_final: prev: {
      xfce =
        prev.xfce
        // {
          tumbler = prev.xfce.tumbler.overrideAttrs (old: {
            buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
          });
        };
    })
    # Pacotes customizados locais (pkgs/default.nix)
    # Adicione novos pacotes lá e exponha-os com callPackage.
    (final: _prev: let
      customPkgs = import ../../pkgs/default.nix {pkgs = final;};
    in
      customPkgs)
  ];
}
