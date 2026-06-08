{
  inputs,
  host,
  ...
}: let
  # Import the host-specific variables.nix
  vars = import ../../hosts/${host}/variables.nix;
  edition = vars.edition or "basic";
  tailscaleEnable = vars.tailscaleEnable or false;
  # Select the system-level edition module
  editionModule =
    if edition == "full"
    then ../../modules/editions/full.nix
    else if edition == "medium"
    then ../../modules/editions/medium.nix
    else if edition == "vm"
    then ../../modules/editions/vm.nix
    else ../../modules/editions/basic.nix; # default: basic
in {
  imports =
    [
      ./boot.nix
      ./flatpak.nix
      ./fonts.nix
      ./hardware.nix
      ./network.nix
      ./nfs.nix
      ./nh.nix
      ./quickshell.nix
      ./packages.nix
      ./printing.nix
      # Conditionally import the display manager module
      (
        if vars.displayManager == "tui"
        then ./ly.nix
        else ./sddm.nix
      )
      ./security.nix
      ./services.nix
      ./steam.nix
      ./stylix.nix
      ./syncthing.nix
      ./system.nix
      ./secrets.nix
      ./thunar.nix
      ./user.nix
      ./virtualisation.nix
      ./xserver.nix
      ./cachix.nix
      inputs.stylix.nixosModules.stylix
      # Edition feature layer (non-visual, additive)
      editionModule
    ]
    # Tailscale VPN — only enabled if tailscaleEnable = true in variables.nix.
    # After rebuild, run: sudo tailscale up
    ++ (
      if tailscaleEnable
      then [./tailscale.nix]
      else []
    );
}
