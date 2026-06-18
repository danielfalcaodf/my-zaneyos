{pkgs, ...}: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      glib
      util-linux
      libGL
      glibc
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      freetype
      fontconfig
      dbus
      expat
      nspr
      nss
      libdrm
      mesa
    ];
  };

  security = {
    rtkit.enable = true;
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if ( subject.isInGroup("users") && (
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          ))
          { return polkit.Result.YES; }
        })
      '';
    };
    pam.services.swaylock = {
      text = ''auth include login '';
    };
    pam.services.login = {
      enableGnomeKeyring = true;
    };
  };
}
