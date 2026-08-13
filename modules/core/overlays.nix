{...}: {
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pFinal: pPrev: {
            nanoemoji = pPrev.nanoemoji.overrideAttrs (old: {
              src = old.src.overrideAttrs (_: {
                outputHash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
              });
            });
          })
        ];
      dwarfs = (prev.dwarfs.override {
        fmt = prev.fmt_11;
      }).overrideAttrs (old: {
        env = (old.env or {}) // {
          CXXFLAGS = (old.env.CXXFLAGS or "") + " -include cstring -Wno-error";
        };
        cmakeFlags = (old.cmakeFlags or []) ++ ["-DENABLE_WERROR=OFF"];
      });
    })
  ];
}
