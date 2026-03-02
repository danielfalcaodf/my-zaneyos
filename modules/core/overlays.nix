{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default

    # pkgs.unstable overlay for bleeding edge applications
    (_final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    })
    # Prefer stable mpv-with-scripts and yt-dlp to avoid deno source builds
    (final: _prev: {
      mpv-with-scripts = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.mpv-with-scripts;
      yt-dlp = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.yt-dlp;
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
