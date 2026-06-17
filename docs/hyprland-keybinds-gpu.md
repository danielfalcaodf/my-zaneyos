# Hyprland: Atalhos GUI e Monitoramento GPU

## 1. Interface Gráfica de Atalhos (Keybinds Viewer)

### Atalhos Configurados

| Atalho | Ação |
|--------|------|
| `SUPER + SHIFT + K` | Abre GUI de atalhos (rofi/wofi/yad) |
| `SUPER + CTRL + K` | Abre GUI de atalhos (yad tabela) |
| `SUPER + ALT + V` | Abre VSCode |
| `SUPER + V` | Clipboard History (rofi) |
| `SUPER + MINUS` | Minimizar janela (move para special:minimize) |
| `SUPER + SHIFT + MINUS` | Restaurar janela minimizada (toggle special:minimize) |

### Scripts Disponíveis

```bash
# GUI principal (auto-detecta rofi/wofi/yad)
hyprland-keybinds

# Versão yad com tabela formatada
hyprland-keybinds-yad

# Copiar atalho para clipboard
hyprland-keybinds-copy
```

### Novos Atalhos de Janela (Hyprland v0.45+)

| Atalho | Ação |
|--------|------|
| `SUPER + MINUS` | Minimizar janela (move para workspace especial `special:minimize`) |
| `SUPER + SHIFT + MINUS` | Restaurar janela minimizada (toggle `special:minimize`) |

> **Nota**: O Hyprland não tem dispatchers nativos `minimize`/`restore`. A implementação usa **special workspace** (`special:minimize`) que é destruído automaticamente quando vazio (`onCreatedEmpty, destroy`).

### Como Funciona

1. **hyprland-keybinds**: Detecta automaticamente `rofi`, `wofi` ou `yad` e mostra os binds do `hyprctl binds -j`
2. **hyprland-keybinds-yad**: Usa `yad` com colunas (Tecla, Descrição, Ação) e busca
3. **hyprland-keybinds-copy**: Permite copiar o atalho selecionado para clipboard

### Instalação dos Launchers (se necessário)

```bash
# rofi (recomendado)
nix shell nixpkgs#rofi

# wofi
nix shell nixpkgs#wofi

# yad (tabela bonita)
nix shell nixpkgs#yad
```

## 2. Atalho VSCode

| Atalho | Comando |
|--------|---------|
| `SUPER + V` | `code` (VSCode) |

## 3. Monitoramento GPU na Waybar

### Módulo Adicionado: `custom/nvidia-gpu`

**Exibição**: `GPU% 󰢮 VRAM% 󰍛` (ex: `45% 󰢮 67% 󰍛`)

**Tooltip**: 
```
GPU: 45%
VRAM: 8.0GB / 12.0GB
Temp: 52°C
Power: 85.5W
```

**Clique esquerdo**: Abre `nvtop` (ou `btop` fallback)
**Clique direito**: Abre `nvtop` via WaybarScripts

### Script WaybarScripts.sh

Localização: `~/.config/hypr/scripts/WaybarScripts.sh`

```bash
WaybarScripts.sh --nvtop   # Abre nvtop no kitty
WaybarScripts.sh --btop    # Abre btop no kitty
WaybarScripts.sh --nmtui   # Abre nmtui
WaybarScripts.sh --files   # Abre Thunar
WaybarScripts.sh --term    # Abre Kitty
```

### Requisitos

```bash
# nvtop para monitoramento GPU detalhado
nix shell nixpkgs#nvtop

# btop como fallback
nix shell nixpkgs#btop

# nvidia-smi (já incluso no driver NVIDIA)
```

### Configuração Waybar (waybar-mangowc-jak-catppuccin.nix)

```nix
"custom/nvidia-gpu" = {
  interval = 2;  # Atualiza a cada 2s
  format = "{gpu}% 󰢮 {vram}% 󰍛";
  exec = "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits | awk ...";
  "return-type" = "json";
  "on-click" = "nvtop";
};
```

## 4. Verificação Pós-Rebuild

```bash
# Testar keybinds GUI
hyprland-keybinds

# Testar Waybar GPU module
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits

# Verificar se WaybarScripts.sh existe
ls -la ~/.config/hypr/scripts/WaybarScripts.sh

# Reiniciar Waybar para aplicar mudanças
pkill waybar && waybar &
```