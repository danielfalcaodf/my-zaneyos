# Hyprland Keybinds Copy — Copia atalho selecionado para clipboard
{pkgs, ...}:
pkgs.writeShellScriptBin "hyprland-keybinds-copy" ''
  #!/usr/bin/env bash
  # Hyprland Keybinds Copy
  # Permite copiar o atalho selecionado para o clipboard

  set -euo pipefail

  # Detectar launcher disponível
  if command -v rofi &>/dev/null; then
    LAUNCHER="rofi -dmenu -i -p 'Hyprland Keybinds (Copiar)' -theme-str 'window {width: 80%;} listview {lines: 30;}'"
  elif command -v wofi &>/dev/null; then
    LAUNCHER="wofi --dmenu -i -p 'Hyprland Keybinds (Copiar)' --width 800 --height 600"
  elif command -v yad &>/dev/null; then
    LAUNCHER="yad --list --title='Hyprland Keybinds (Copiar)' --column=Key --column=Description --column=Action --width=900 --height=600 --separator=, --print-column=1"
  else
    notify-send "Hyprland Keybinds Copy" "Nenhum launcher encontrado (rofi/wofi/yad)"
    exit 1
  fi

  # Obter binds do Hyprland via hyprctl
  BINDS=$(hyprctl binds -j | jq -r '
    .[] |
    "\(.key // .keycode // "?"), \(.description // "Sem descrição"), \(.dispatcher // "") \(.arg // "")"
  ' | sort -u)

  if [[ -z "$BINDS" ]]; then
    notify-send "Hyprland Keybinds Copy" "Nenhum atalho encontrado"
    exit 1
  fi

  # Mostrar no launcher e copiar seleção
  SELECTED=$(echo "$BINDS" | eval "$LAUNCHER")

  if [[ -n "$SELECTED" ]]; then
    # Extrair apenas a tecla (primeira coluna antes da vírgula)
    KEY=$(echo "$SELECTED" | cut -d',' -f1 | xargs)
    echo -n "$KEY" | wl-copy
    notify-send "Hyprland Keybinds Copy" "Copiado para clipboard: $KEY"
  fi
''