{pkgs, ...}: {
  home.packages = [pkgs.lan-mouse];

  # Autostart lan-mouse daemon with the Hyprland session.
  # Configure peers and layout via the Web UI at http://localhost:4242
  systemd.user.services.lan-mouse = {
    Unit = {
      Description = "lan-mouse — LAN mouse and keyboard sharing daemon";
      After = ["hyprland-session.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --daemon";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}
