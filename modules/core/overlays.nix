{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default

    # Pin Neovim to 0.11.6 (zos-next)
    (_final: prev: let
      tree-sitter-src-0_25_9 = prev.fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter";
        rev = "v0.25.9";
        hash = "sha256-i7sptOJuLPSl0v8qYF54zfvVKOUtekcFedqapxehzWI=";
      };
      tree-sitter-cargo-deps-0_25_9 = prev.rustPlatform.fetchCargoVendor {
        name = "tree-sitter-0.25.9-vendor";
        src = tree-sitter-src-0_25_9;
        hash = "";
      };
      tree-sitter-0_25_9 = prev.tree-sitter.overrideAttrs (_old: {
        version = "0.25.9";
        src = tree-sitter-src-0_25_9;
        cargoDeps = tree-sitter-cargo-deps-0_25_9;
      });
      neovim-unwrapped-0_11_6 = prev.neovim-unwrapped.overrideAttrs (_old: {
        version = "0.11.6";
        src = prev.fetchFromGitHub {
          owner = "neovim";
          repo = "neovim";
          rev = "v0.11.6";
          hash = "sha256-GdfCaKNe/qPaUV2NJPXY+ATnQNWnyFTFnkOYDyLhTNg=";
        };
      });
    in {
      tree-sitter = tree-sitter-0_25_9;
      neovim-unwrapped = neovim-unwrapped-0_11_6;
      neovim = prev.neovim.override {neovim-unwrapped = neovim-unwrapped-0_11_6;};
    })

    # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
    (_final: prev: {
      xfce = prev.xfce // {
        tumbler = prev.xfce.tumbler.overrideAttrs (old: {
          buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
        });
      };
    })
  ];
}
