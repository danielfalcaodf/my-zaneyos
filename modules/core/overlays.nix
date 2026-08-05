{...}: {
  nixpkgs.overlays = [
    # Fix Hyprland 0.56+ build with glaze 8.0.0 in nixpkgs-unstable
    (_final: prev: {
      hyprland = prev.hyprland.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            if [ -f CMakeLists.txt ] && grep -q "find_package(glaze 7\.\.\.<8" CMakeLists.txt; then
              substituteInPlace CMakeLists.txt \
                --replace-fail "find_package(glaze 7...<8 QUIET)" "find_package(glaze REQUIRED)"
            fi
          '';
      });
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
