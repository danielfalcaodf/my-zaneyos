# Hyprland Keybinds Viewer — GUI para listar todos os atalhos
# Abre via rofi/wofi/yad mostrando binds ativos do Hyprland
{pkgs, ...}:
pkgs.writeShellScriptBin "hyprland-keybinds" ''
  #!/usr/bin/env bash
  # Hyprland Keybinds Viewer
  # Mostra todos os atalhos configurados em uma interface gráfica

  set -euo pipefail

  # Detectar launcher disponível
  if command -v rofi &>/dev/null; then
    LAUNCHER="rofi -dmenu -i -p 'Hyprland Keybinds' -theme-str 'window {width: 80%;} listview {lines: 30;}'"
  elif command -v wofi &>/dev/null; then
    LAUNCHER="wofi --dmenu -i -p 'Hyprland Keybinds' --width 800 --height 600"
  elif command -v yad &>/dev/null; then
    LAUNCHER="yad --list --title='Hyprland Keybinds' --column=Key --column=Description --column=Action --width=900 --height=600"
  else
    notify-send "Hyprland Keybinds" "Nenhum launcher encontrado (rofi/wofi/yad)"
    exit 1
  fi

  # Obter binds do Hyprland via hyprctl
  # Formato: key, description, action
  BINDS=$(hyprctl binds -j | jq -r '
    .[] |
    "\(.key // .keycode // "?"), \(.description // "Sem descrição"), \(.dispatcher // "") \(.arg // "")"
  ' | sort -u)

  if [[ -z "$BINDS" ]]; then
    notify-send "Hyprland Keybinds" "Nenhum atalho encontrado"
    exit 1
  fi

  # Mostrar no launcher
  echo "$BINDS" | eval "$LAUNCHER"
''