# Waybar Scripts — Helper scripts for Waybar modules
# Installed to ~/.config/hypr/scripts/WaybarScripts.sh
{pkgs, ...}:
pkgs.writeShellScriptBin "WaybarScripts" ''
  #!/usr/bin/env bash
  # WaybarScripts — Helper scripts for Waybar modules
  # Usage: WaybarScripts.sh [--nvtop|--btop|--nmtui|--files|--term]

  set -euo pipefail

  case "''${1:-}" in
    --nvtop)
      # Open nvtop in terminal for GPU monitoring
      if command -v nvtop &>/dev/null; then
        kitty --title "nvtop" -e nvtop
      elif command -v btop &>/dev/null; then
        kitty --title "btop" -e btop
      else
        notify-send "Waybar" "nvtop/btop not installed"
      fi
      ;;
    --btop)
      # Open btop in terminal
      if command -v btop &>/dev/null; then
        kitty --title "btop" -e btop
      else
        notify-send "Waybar" "btop not installed"
      fi
      ;;
    --nmtui)
      # Open NetworkManager TUI
      kitty --title "nmtui" -e nmtui
      ;;
    --files)
      # Open file manager
      thunar &
      ;;
    --term)
      # Open terminal
      kitty &
      ;;
    *)
      echo "Usage: WaybarScripts.sh [--nvtop|--btop|--nmtui|--files|--term]"
      exit 1
      ;;
  esac
''