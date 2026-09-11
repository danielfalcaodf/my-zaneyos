{
  pkgs,
  lib,
  ...
}: {
  # Only enable either docker or podman -- Not both.
  # lib.mkDefault allows edition modules (e.g. vm.nix) to override with false.
  virtualisation = {
    docker = {
      enable = lib.mkDefault true;
      # Log rotation: prevents /var/lib/docker/containers/*/*-json.log filling disk
      daemon.settings = {
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
        # Disable userland proxy: better performance, less attack surface
        userland-proxy = false;
      };
    };

    podman.enable = false;

    libvirtd = {
      enable = lib.mkDefault true;
    };

    virtualbox.host = {
      enable = false;
      enableExtensionPack = true;
    };
  };

  programs = {
    virt-manager.enable = false;
  };

  systemd.services.systemd-machined = {
    stopIfChanged = false;
    restartIfChanged = false;
  };

  environment.systemPackages = with pkgs; [
    virt-viewer # View Virtual Machines
    lazydocker
    docker-client
  ];
}
