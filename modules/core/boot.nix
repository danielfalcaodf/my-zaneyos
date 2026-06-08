{
  pkgs,
  lib,
  config,
  host,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  edition = vars.edition or "basic";

  # Sleek GRUB theme — dark style
  grubTheme = pkgs.sleek-grub-theme.override {withStyle = "dark";};
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["v4l2loopback"];
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        # "nodev" = UEFI mode (no MBR device required)
        device = "nodev";

        # Label shown for the NixOS entry in the GRUB menu
        configurationName = "Nixos - Dev Homelab";

        # Beautiful dark theme (mkForce overrides Stylix's grub theme)
        theme = lib.mkForce "${grubTheme}";

        # os-prober scans for other OSes; kept as detection fallback
        useOSProber = true;

        # Custom Windows entry with friendly name.
        # The EFI UUID 3D69-A64E is /dev/sda1 — the shared EFI partition
        # where the Windows Ghost installer placed its boot files.
        extraEntries = ''
          menuentry "Win 11 Ghost 25H2 - Gamer" --class windows --class os {
            insmod part_gpt
            insmod fat
            search --no-floppy --fs-uuid --set=root 3D69-A64E
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';

        # Show menu for 10 seconds before auto-booting NixOS
        extraConfig = ''
          set timeout=10
          set timeout_style=menu
        '';
      };
    };

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
