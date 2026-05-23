# zaneyos-check — post-install validation script.
# Verifies packages, system services and Docker stacks are correctly
# installed for the active edition. Prints fix commands for anything missing.
{
  pkgs,
  host,
  ...
}: let
  vars = import ../../../hosts/${host}/variables.nix;
  edition = vars.edition or "basic";
  stacks = "$HOME/zaneyos/docker/stacks";
in
  pkgs.writeShellScriptBin "zaneyos-check" ''
    #!/usr/bin/env bash
    set -euo pipefail

    EDITION="${edition}"
    STACKS_DIR="${stacks}"

    # ── colours ──────────────────────────────────────────────────────────────
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'

    PASS=0; WARN=0; FAIL=0
    # note: use PASS=$((PASS+1)) — ((PASS++)) exits with set -e when value was 0

    # ── helpers ───────────────────────────────────────────────────────────────
    section() { echo -e "\n''${CYAN}''${BOLD}━━━ $1 ━━━''${NC}"; }

    ok()   { echo -e "  ''${GREEN}✓''${NC} $1"; PASS=$((PASS+1)); }
    warn() { echo -e "  ''${YELLOW}⚠''${NC}  $1"; WARN=$((WARN+1)); }
    fail() { echo -e "  ''${RED}✗''${NC} $1"; FAIL=$((FAIL+1)); }
    hint() { echo -e "       ''${YELLOW}→ $1''${NC}"; }
    info() { echo -e "  ''${CYAN}ℹ''${NC}  $1"; }

    check_cmd() {
      local bin="$1" label="''${2:-$1}"
      if command -v "$bin" &>/dev/null; then
        ok "$label  ($(command -v "$bin"))"
      else
        fail "$label não encontrado"
        hint "Verifique a edição '$EDITION' e rode: zcli rebuild"
      fi
    }

    check_service() {
      local svc="$1" label="''${2:-$1}"
      local st
      st=$(systemctl is-active "$svc" 2>/dev/null || true)
      case "$st" in
        active)   ok   "Serviço $label: ativo" ;;
        inactive) fail "Serviço $label: inativo"
                  hint "sudo systemctl enable --now $svc" ;;
        *)        fail "Serviço $label: $st"
                  hint "sudo systemctl status $svc  (para diagnóstico)" ;;
      esac
    }

    check_stack() {
      local container="$1" path="$2" label="''${3:-$1}"
      local st
      st=$(docker ps --filter "name=^''${container}$" --format "{{.Status}}" 2>/dev/null | head -1)
      if [ -n "$st" ]; then
        ok "Stack $label: $st"
      else
        # container exists but stopped?
        local stopped
        stopped=$(docker ps -a --filter "name=^''${container}$" --format "{{.Status}}" 2>/dev/null | head -1)
        if [ -n "$stopped" ]; then
          warn "Stack $label parado ($stopped)"
          hint "cd $path && docker compose start"
        else
          fail "Stack $label não encontrado"
          hint "cd $path && docker compose up -d"
        fi
      fi
    }

    # ── header ────────────────────────────────────────────────────────────────
    echo ""
    echo -e "''${CYAN}╔═══════════════════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║         ZaneyOS — Validação Pós-Instalação                            ║''${NC}"
    echo -e "''${CYAN}║  Edição : ''${BOLD}$EDITION''${NC}''${CYAN}                                                        ║''${NC}"
    echo -e "''${CYAN}║  Host   : ''${BOLD}$(hostname)''${NC}''${CYAN}                                                       ║''${NC}"
    echo -e "''${CYAN}╚═══════════════════════════════════════════════════════════════════════╝''${NC}"

    # ── sistema base ──────────────────────────────────────────────────────────
    section "Sistema Base"
    check_cmd "nix"    "Nix"
    check_cmd "git"    "Git"
    check_cmd "zcli"   "zcli"

    GEN=$(nixos-rebuild list-generations 2>/dev/null | awk '/\(current\)/{print $1}' || echo "?")
    info "Geração NixOS ativa: $GEN"

    # ── serviços base ─────────────────────────────────────────────────────────
    section "Serviços Base"
    check_service "NetworkManager"    "NetworkManager"
    check_service "pipewire"          "PipeWire (áudio)"
    check_service "sshd"              "OpenSSH"

    # ── docker ────────────────────────────────────────────────────────────────
    section "Docker"
    if [ "$EDITION" = "vm" ]; then
      info "Edição VM: Docker desabilitado (comportamento esperado)."
    else
      check_service "docker" "Docker daemon"

      if systemctl is-active docker &>/dev/null; then
        if id -nG "$USER" 2>/dev/null | grep -qw docker; then
          ok "Usuário '$USER' está no grupo docker"
        else
          warn "Usuário '$USER' NÃO está no grupo docker"
          hint "sudo usermod -aG docker $USER  (depois faça logout/login)"
        fi

        # ── stacks: básico (basic / medium / full) ─────────────────────────
        section "Docker Stacks — Homelab"
        check_stack "portainer" "$STACKS_DIR/homelab/portainer" "Portainer"
        check_stack "caddy"     "$STACKS_DIR/homelab/caddy"     "Caddy"
        check_stack "homepage"  "$STACKS_DIR/homelab/homepage"  "Homepage"

        if [ "$EDITION" = "medium" ] || [ "$EDITION" = "full" ]; then
          section "Docker Stacks — Databases & Monitoring"
          check_stack "postgres"   "$STACKS_DIR/databases/postgres"    "PostgreSQL"
          check_stack "redis"      "$STACKS_DIR/databases/redis"       "Redis"
          check_stack "prometheus" "$STACKS_DIR/monitoring/prometheus" "Prometheus"
          check_stack "grafana"    "$STACKS_DIR/monitoring/grafana"    "Grafana"
          check_stack "loki"       "$STACKS_DIR/monitoring/loki"       "Loki"
          check_stack "n8n"        "$STACKS_DIR/automation/n8n"        "n8n"
          check_stack "mailpit"    "$STACKS_DIR/automation/mailpit"    "Mailpit"
        fi

        if [ "$EDITION" = "full" ]; then
          section "Docker Stacks — Full"
          check_stack "mysql"        "$STACKS_DIR/databases/mysql"        "MySQL"
          check_stack "cloudbeaver"  "$STACKS_DIR/databases/cloudbeaver"  "CloudBeaver"
          check_stack "adminer"      "$STACKS_DIR/databases/adminer"      "Adminer"
          check_stack "minio"        "$STACKS_DIR/storage/minio"          "MinIO"
          check_stack "open-webui"   "$STACKS_DIR/llm/open-webui"         "Open WebUI (LLM)"
        fi
      fi
    fi

    # ── pacotes por edição ────────────────────────────────────────────────────
    section "Pacotes — Edição: $EDITION"

    # todos as edições
    check_cmd "node"   "Node.js"
    check_cmd "pnpm"   "pnpm"
    check_cmd "biome"  "biome"
    check_cmd "nil"    "nil (Nix LSP)"

    if [ "$EDITION" != "vm" ]; then
      check_cmd "lazygit"  "lazygit"
      check_cmd "gh"       "GitHub CLI"
      check_cmd "mise"     "mise"
      check_cmd "python3"  "Python 3"
      check_cmd "uv"       "uv"
      check_cmd "ruff"     "ruff"
      check_cmd "psql"     "PostgreSQL client"
      check_cmd "code"     "VS Code"
      check_cmd "duf"      "duf"
      check_cmd "ncdu"     "ncdu"
      check_cmd "typescript-language-server" "typescript-language-server"
      check_cmd "bash-language-server"       "bash-language-server"
      check_cmd "yaml-language-server"       "yaml-language-server"
    fi

    if [ "$EDITION" = "medium" ] || [ "$EDITION" = "full" ]; then
      check_cmd "kubectl"    "kubectl"
      check_cmd "k9s"        "k9s"
      check_cmd "helm"       "Helm"
      check_cmd "terraform"  "Terraform"
      check_cmd "aws"        "AWS CLI"
      check_cmd "gcloud"     "Google Cloud SDK"
      check_cmd "dbeaver"    "DBeaver"
      check_cmd "zellij"     "zellij"
      check_cmd "pre-commit" "pre-commit"
    fi

    if [ "$EDITION" = "full" ]; then
      check_cmd "k3d"     "k3d"
      check_cmd "aichat"  "aichat"
      check_cmd "firebase" "firebase-tools"
    fi

    # ── sumário ───────────────────────────────────────────────────────────────
    echo ""
    echo -e "''${CYAN}''${BOLD}━━━ Sumário ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo -e "  ''${GREEN}✓ Passou : $PASS''${NC}"
    echo -e "  ''${YELLOW}⚠ Avisos : $WARN''${NC}"
    echo -e "  ''${RED}✗ Falhou : $FAIL''${NC}"
    echo ""

    if [ "$FAIL" -gt 0 ]; then
      echo -e "''${RED}''${BOLD}❌ Falhas críticas detectadas.''${NC}"
      echo -e "   Corrija os itens acima e, se necessário:"
      echo -e "   ''${YELLOW}→ zcli rebuild''${NC}                    (rebuildar a config atual)"
      echo -e "   ''${YELLOW}→ bash ~/zaneyos/install-zaneyos.sh''${NC} (reinstalar do zero)"
    elif [ "$WARN" -gt 0 ]; then
      echo -e "''${YELLOW}⚠️  Sistema funcional mas com avisos. Revise os itens marcados com ⚠.''${NC}"
    else
      echo -e "''${GREEN}''${BOLD}🎉 Tudo verificado! Sistema instalado e configurado corretamente.''${NC}"
    fi
    echo ""
  ''
