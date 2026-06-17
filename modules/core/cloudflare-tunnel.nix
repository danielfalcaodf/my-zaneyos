{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cloudflare-tunnel;
in {
  options.services.cloudflare-tunnel = {
    enable = lib.mkEnableOption "Enable Cloudflare Tunnel (cloudflared)";

    # File containing the token: TUNNEL_TOKEN=seu_token_aqui
    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the Cloudflare Tunnel token.
        The file MUST contain a single line like this:
        TUNNEL_TOKEN=seu_token_gigante_aqui
      '';
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "zaneyos-homelab";
      description = "Tunnel name (for description only)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the correct package
    environment.systemPackages = [pkgs.cloudflared];

    systemd.services.cloudflare-tunnel = {
      description = "Cloudflare Tunnel (${cfg.name})";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
        # Securely loads the TUNNEL_TOKEN environment variable
        EnvironmentFile = cfg.tokenFile;
        # --no-autoupdate is mandatory on NixOS
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      };
    };
  };
}
