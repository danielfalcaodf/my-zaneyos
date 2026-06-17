# Hyprland Keybinds Viewer — Versão YAD com tabela formatada
{pkgs, ...}:
pkgs.writeShellScriptBin "hyprland-keybinds-yad" ''
  #!/usr/bin/env bash
  # Hyprland Keybinds Viewer - YAD Table Version
  # Mostra todos os atalhos em uma tabela formatada com busca

  set -euo pipefail

  if ! command -v yad &>/dev/null; then
    notify-send "Hyprland Keybinds" "yad não encontrado. Instale com: nix shell nixpkgs#yad"
    exit 1
  fi

  # Obter binds do Hyprland via hyprctl
  BINDS=$(hyprctl binds -j | jq -r '
    .[] |
    "\(.key // .keycode // "?"), \(.description // "Sem descrição"), \(.dispatcher // "") \(.arg // "")"
  ' | sort -u)

  if [[ -z "$BINDS" ]]; then
    notify-send "Hyprland Keybinds" "Nenhum atalho encontrado"
    exit 1
  fi

  # Header para YAD
  echo "$BINDS" | yad --list \
    --title="Hyprland Keybinds" \
    --column="Tecla" \
    --column="Descrição" \
    --column="Ação" \
    --width=1000 \
    --height=700 \
    --search-column=2 \
    --button="Fechar:0" \
    --button="Copiar Selecionado:1" \
    --separator="," \
    --no-click \
    --dclick-action="bash -c 'echo %s | cut -d\",\" -f1 | wl-copy'"
''