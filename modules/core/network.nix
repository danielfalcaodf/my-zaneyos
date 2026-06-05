{
  pkgs,
  host,
  options,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  inherit (vars) hostId;
  lanMouseEnable = vars.lanMouseEnable or false;
in {
  networking = {
    hostName = "${host}";
    hostId = hostId;
    networkmanager.enable = true;
    timeServers = options.networking.timeServers.default ++ ["pool.ntp.org"];
    firewall = {
      enable = true;
      allowedTCPPorts =
        [
          22
          80
          443
          59010
          59011
          8080
        ]
        ++ (
          if lanMouseEnable
          then [4242]
          else []
        );
      allowedUDPPorts =
        [
          59010
          59011
        ]
        ++ (
          if lanMouseEnable
          then [4242]
          else []
        );
    };
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
