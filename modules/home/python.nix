{pkgs, ...}: {
  home.packages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.setuptools
    python3Packages.black
    python3Packages.flake8
    python3Packages.mypy
    python3Packages.requests
    uv # Modern Python package manager (replaces pip for most use cases)
  ];

  # pip configuration — always use --user installs on NixOS
  home.file.".config/pip/pip.conf".text = ''
    [global]
    user = true
    no-warn-script-location = false
  '';

  # Environment variables for Python development
  home.sessionVariables = {
    PIP_USER = "1";
    # Ensure uv uses the right cache directory
    UV_CACHE_DIR = "$HOME/.cache/uv";
  };

  # Create a wrapper script for Weather.py to ensure it uses Python with required packages
  home.file.".local/bin/weather" = {
    text = ''
      #!/bin/sh
      exec ${pkgs.python3.withPackages (p: [p.requests])}/bin/python3 $HOME/.config/waybar/scripts/Weather.py "$@"
    '';
    executable = true;
  };

  # Set Python path in environment
  home.sessionPath = [
    "${pkgs.python3}/bin"
    "$HOME/.local/bin"
  ];
}
