{pkgs, ...}: {
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
    wrappers.pkexec = {
      source = "${pkgs.polkit.bin}/bin/pkexec";
      owner = "root";
      group = "root";
      setuid = true;
    };
    pam.services.swaylock = {
      text = ''auth include login '';
    };
  };
}
