{
  pkgs,
  config,
  host,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  edition = vars.edition or "basic";
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["v4l2loopback"];
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
    # Plymouth disabled for vm edition (lighter boot, no GPU animation)
    plymouth.enable = edition != "vm";
  };
}
