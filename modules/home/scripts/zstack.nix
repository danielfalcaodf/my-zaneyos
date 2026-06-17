{host, pkgs, ...}: let
  zstackScript = ./zstack.sh;
in
  pkgs.writeShellScriptBin "zstack" (builtins.readFile zstackScript)
