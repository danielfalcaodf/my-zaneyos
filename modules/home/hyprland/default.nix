{zaneyos, ...}: let
  inherit (zaneyos) animChoice;
in {
  imports = [
    animChoice
    ./binds.nix
    ./env.nix
    ./exec-once.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./windowrules.nix
  ];
}
