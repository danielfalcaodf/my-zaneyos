# zstack — Gerenciador de Docker Stacks para ZaneyOS Homelab
# Uso: zstack <comando> [argumentos]
{pkgs}: let
  stacksRoot = "$HOME/zaneyos/docker/stacks";
in
  pkgs.writeShellScriptBin "zstack" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # ─── Cores ────────────────────────────────────────────────────────────────
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    # ─── Diretório raiz das stacks ────────────────────────────────────────────
    STACKS_ROOT="${stacksRoot}"

    # ─── Funções auxiliares ───────────────────────────────────────────────────
    info()    { echo -e "''${CYAN}ℹ''${NC}  $*"; }
    ok()      { echo -e "''${GREEN}✔''${NC}  $*"; }
    warn()    { echo -e "''${YELLOW}⚠''${NC}  $*"; }
    err()     { echo -e "''${RED}✘''${NC}  $*" >&2; }
    die()     { err "$*"; exit 1; }
    section() { echo -e "\n''${BLUE}━━ $* ━━''${NC}"; }

    # Encontra o arquivo compose de uma stack (compose.yml ou docker-compose.yml)
    find_compose() {
      local dir="$1"
      if [[ -f "$dir/compose.yml" ]]; then
        echo "$dir/compose.yml"
      elif [[ -f "$dir/docker-compose.yml" ]]; then
        echo "$dir/docker-compose.yml"
      else
        echo ""
      fi
    }

    # Resolve o diretório de uma stack a partir de "categoria/stack" ou "categoria"
    resolve_stack_dir() {
      local arg="$1"
      local dir="$STACKS_ROOT/$arg"
      if [[ ! -d "$dir" ]]; then
        die "Stack não encontrada: $arg (procurado em $dir)"
      fi
      echo "$dir"
    }

    # Executa docker compose em um diretório, validando o compose file
    run_compose() {
      local dir="$1"
      shift
      local compose_file
      compose_file="$(find_compose "$dir")"
      if [[ -z "$compose_file" ]]; then
        die "Nenhum compose.yml ou docker-compose.yml encontrado em: $dir"
      fi
      (cd "$dir" && docker compose -f "$(basename "$compose_file")" "$@")
    }

    # ─── Comandos ─────────────────────────────────────────────────────────────

    cmd_list() {
      local category=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --category|-c) shift; category="$1"; shift ;;
          *) die "Argumento desconhecido: $1" ;;
        esac
      done

      if [[ ! -d "$STACKS_ROOT" ]]; then
        die "Diretório de stacks não encontrado: $STACKS_ROOT"
      fi

      section "Stacks disponíveis"

      list_category() {
        local cat_dir="$1"
        local cat
        cat="$(basename "$cat_dir")"
        echo -e "''${CYAN}$cat/''${NC}"

        # Root compose da categoria (ex: automation/compose.yml)
        local root_compose
        root_compose="$(find_compose "$cat_dir")"
        if [[ -n "$root_compose" ]]; then
          local has_env=""
          if find "$cat_dir"* -maxdepth 1 -name ".env" -type f 2>/dev/null | grep -q .; then
            has_env="''${GREEN}[.env OK]''${NC}"
          else
            has_env="''${YELLOW}[inicie com: zstack init $cat]''${NC}"
          fi
          echo -e "  ├─ ''${BLUE}[ROOT]''${NC}  ''${GREEN}[compose]''${NC}  $has_env  → zstack up $cat"
        fi

        # Stacks individuais (sub-pastas com compose.yml)
        for stack_dir in "$cat_dir"*/; do
          [[ -d "$stack_dir" ]] || continue
          local stack
          stack="$(basename "$stack_dir")"
          local compose_file
          compose_file="$(find_compose "$stack_dir")"
          local has_env=""
          [[ -f "$stack_dir/.env" ]] && has_env="''${GREEN}[.env OK]''${NC}" || has_env="''${YELLOW}[sem .env]''${NC}"
          local has_compose=""
          [[ -n "$compose_file" ]] && has_compose="''${GREEN}[compose]''${NC}" || has_compose="''${RED}[sem compose]''${NC}"
          echo -e "  ├─ $stack  $has_compose  $has_env"
        done
      }

      if [[ -n "$category" ]]; then
        local cat_dir="$STACKS_ROOT/$category"
        [[ -d "$cat_dir" ]] || die "Categoria não encontrada: $category"
        list_category "$cat_dir"
      else
        for cat_dir in "$STACKS_ROOT"/*/; do
          [[ -d "$cat_dir" ]] || continue
          list_category "$cat_dir"
        done
      fi
    }

    cmd_init() {
      local target="''${1:-}"

      init_stack() {
        local stack_dir="$1"
        local label="$2"
        if [[ ! -f "$stack_dir/.env.example" ]]; then
          warn "$label: sem .env.example — pulando"
          return
        fi
        if [[ -f "$stack_dir/.env" ]]; then
          info "$label: .env já existe — não sobrescrito"
          return
        fi
        cp "$stack_dir/.env.example" "$stack_dir/.env"
        ok "$label: .env criado a partir de .env.example"
        warn "$label: PREENCHA manualmente o .env antes de subir!"
      }

      if [[ -z "$target" ]]; then
        section "Inicializando todas as stacks"
        for cat_dir in "$STACKS_ROOT"/*/; do
          [[ -d "$cat_dir" ]] || continue
          local cat
          cat="$(basename "$cat_dir")"
          for stack_dir in "$cat_dir"*/; do
            [[ -d "$stack_dir" ]] || continue
            local stack
            stack="$(basename "$stack_dir")"
            init_stack "$stack_dir" "$cat/$stack"
          done
        done
      elif [[ "$target" == */* ]]; then
        local stack_dir
        stack_dir="$(resolve_stack_dir "$target")"
        section "Inicializando $target"
        init_stack "$stack_dir" "$target"
      else
        local cat_dir="$STACKS_ROOT/$target"
        [[ -d "$cat_dir" ]] || die "Categoria não encontrada: $target"
        section "Inicializando categoria $target"
        for stack_dir in "$cat_dir"*/; do
          [[ -d "$stack_dir" ]] || continue
          local stack
          stack="$(basename "$stack_dir")"
          init_stack "$stack_dir" "$target/$stack"
        done
      fi

      echo ""
      warn "Revise e preencha os .env criados antes de usar 'zstack up'."
    }

    cmd_up() {
      [[ $# -ge 1 ]] || die "Uso: zstack up <categoria> | <categoria/stack>"
      local stack_dir
      stack_dir="$(resolve_stack_dir "$1")"
      section "Subindo $1"
      run_compose "$stack_dir" up -d
      ok "Stack $1 iniciada."
    }

    cmd_down() {
      [[ $# -ge 1 ]] || die "Uso: zstack down <categoria> | <categoria/stack>"
      local stack_dir
      stack_dir="$(resolve_stack_dir "$1")"
      section "Derrubando $1"
      run_compose "$stack_dir" down
      ok "Stack $1 parada."
    }

    cmd_restart() {
      [[ $# -ge 1 ]] || die "Uso: zstack restart <categoria> | <categoria/stack>"
      local stack_dir
      stack_dir="$(resolve_stack_dir "$1")"
      section "Reiniciando $1"
      run_compose "$stack_dir" down
      run_compose "$stack_dir" up -d
      ok "Stack $1 reiniciada."
    }

    cmd_logs() {
      [[ $# -ge 1 ]] || die "Uso: zstack logs <categoria> | <categoria/stack>"
      local stack_dir
      stack_dir="$(resolve_stack_dir "$1")"
      section "Logs de $1"
      run_compose "$stack_dir" logs -f
    }

    cmd_ps() {
      section "Status das stacks"
      local found=0
      for cat_dir in "$STACKS_ROOT"/*/; do
        [[ -d "$cat_dir" ]] || continue
        local cat
        cat="$(basename "$cat_dir")"

        # Root compose da categoria
        local root_compose
        root_compose="$(find_compose "$cat_dir")"
        if [[ -n "$root_compose" ]]; then
          found=1
          echo -e "\n''${BLUE}$cat [ROOT]''${NC}"
          (cd "$cat_dir" && docker compose -f "$(basename "$root_compose")" ps --format table 2>/dev/null) || \
            warn "$cat: falha ao consultar status do root compose"
        fi

        # Stacks individuais (sub-pastas)
        for stack_dir in "$cat_dir"*/; do
          [[ -d "$stack_dir" ]] || continue
          local stack
          stack="$(basename "$stack_dir")"
          local compose_file
          compose_file="$(find_compose "$stack_dir")"
          [[ -n "$compose_file" ]] || continue
          found=1
          echo -e "\n''${CYAN}$cat/$stack''${NC}"
          (cd "$stack_dir" && docker compose -f "$(basename "$compose_file")" ps --format table 2>/dev/null) || \
            warn "$cat/$stack: falha ao consultar status"
        done
      done
      [[ $found -eq 1 ]] || warn "Nenhuma stack com compose encontrada em $STACKS_ROOT"
    }

    cmd_doctor() {
      section "Diagnóstico do ambiente Docker Stacks"
      local ok_count=0
      local warn_count=0

      check() {
        local label="$1"; shift
        if "$@" &>/dev/null; then
          ok "$label"
          ((ok_count++))
        else
          err "$label — FALHOU"
          ((warn_count++))
        fi
      }

      check "Docker instalado"          command -v docker
      check "Docker Compose disponível" docker compose version
      check "Docker daemon acessível"   docker info
      check "Diretório de stacks existe" test -d "$STACKS_ROOT"

      # Verificar .env faltantes
      echo ""
      section "Verificação de .env"
      local missing_env=0
      for cat_dir in "$STACKS_ROOT"/*/; do
        [[ -d "$cat_dir" ]] || continue
        local cat
        cat="$(basename "$cat_dir")"
        for stack_dir in "$cat_dir"*/; do
          [[ -d "$stack_dir" ]] || continue
          local stack
          stack="$(basename "$stack_dir")"
          if [[ -f "$stack_dir/.env.example" && ! -f "$stack_dir/.env" ]]; then
            warn "$cat/$stack: tem .env.example mas está sem .env"
            ((missing_env++))
            ((warn_count++))
          fi
        done
      done
      [[ $missing_env -eq 0 ]] && ok "Todos os .env presentes"

      echo ""
      section "Resultado"
      ok "Verificações OK: $ok_count"
      [[ $warn_count -gt 0 ]] && warn "Avisos/Erros: $warn_count" || ok "Sem avisos"
    }

    cmd_update() {
      [[ $# -ge 1 ]] || die "Uso: zstack update <categoria/stack>"
      local stack_dir
      stack_dir="$(resolve_stack_dir "$1")"
      section "Atualizando $1"
      run_compose "$stack_dir" pull
      run_compose "$stack_dir" up -d --remove-orphans
      ok "Stack $1 atualizada."
    }

    cmd_backup_info() {
      section "Volumes e diretórios persistentes para backup"
      for cat_dir in "$STACKS_ROOT"/*/; do
        [[ -d "$cat_dir" ]] || continue
        local cat
        cat="$(basename "$cat_dir")"
        for stack_dir in "$cat_dir"*/; do
          [[ -d "$stack_dir" ]] || continue
          local stack
          stack="$(basename "$stack_dir")"
          local compose_file
          compose_file="$(find_compose "$stack_dir")"
          [[ -n "$compose_file" ]] || continue
          local volumes
          volumes="$(grep -E '^\s+- [a-zA-Z./].*:' "$compose_file" 2>/dev/null | grep -v 'docker.sock' | sed 's/.*- /  /' || true)"
          if [[ -n "$volumes" ]]; then
            echo -e "''${CYAN}$cat/$stack''${NC}"
            echo "$volumes"
          fi
        done
      done
      echo ""
      info "Volumes Docker nomeados: verifique com 'docker volume ls'"
    }

    cmd_help() {
      cat <<'HELP'
    zstack — Gerenciador de Docker Stacks para ZaneyOS Homelab

    Padrão de diretórios:
      docker/stacks/<categoria>/compose.yml          Root compose (sobe todos os serviços da categoria)
      docker/stacks/<categoria>/<stack>/compose.yml  Compose individual (sobe só aquele serviço)

    Uso:
      zstack list [--category <cat>]          Lista stacks e root composes disponíveis
      zstack init [<cat>/<stack>|<cat>]       Cria .env a partir de .env.example
      zstack up   <cat> | <cat>/<stack>       Sobe o root compose ou stack individual
      zstack down <cat> | <cat>/<stack>       Derruba
      zstack restart <cat> | <cat>/<stack>    Reinicia
      zstack logs <cat> | <cat>/<stack>       Mostra logs (-f)
      zstack ps                               Status de todos os containers
      zstack doctor                           Valida ambiente, .env e Docker
      zstack update <cat> | <cat>/<stack>     Pull de imagens + recreate
      zstack backup-info                      Mostra volumes que precisam backup

    Exemplos:
      zstack list
      zstack list --category automation
      zstack init                             Inicializa .env de TODAS as stacks
      zstack init automation                  Inicializa .env de todas as stacks em automation/
      zstack init automation/woodpecker       Inicializa .env apenas do woodpecker
      zstack up automation                    Sobe todos os serviços de automação (root compose)
      zstack up automation/n8n                Sobe apenas o n8n (compose individual)
      zstack up homelab/homepage
      zstack logs homelab/homepage
      zstack doctor

    Stacks disponíveis:
      homelab/     → portainer, caddy, homepage
      automation/  → mailpit, n8n, uptime-kuma, woodpecker
      databases/   → postgres, mysql, redis, sqlserver, adminer, cloudbeaver
      monitoring/  → grafana, loki, prometheus
      storage/     → minio
      llm/         → open-webui

    As stacks ficam em: ~/zaneyos/docker/stacks/<categoria>/
    Cada stack deve ter compose.yml (ou docker-compose.yml) e .env.example.
    HELP
    }

    # ─── Roteador de comandos ─────────────────────────────────────────────────
    COMMAND="''${1:-help}"
    shift 2>/dev/null || true

    case "$COMMAND" in
      list)        cmd_list "$@" ;;
      init)        cmd_init "$@" ;;
      up)          cmd_up "$@" ;;
      down)        cmd_down "$@" ;;
      restart)     cmd_restart "$@" ;;
      logs)        cmd_logs "$@" ;;
      ps)          cmd_ps "$@" ;;
      doctor)      cmd_doctor "$@" ;;
      update)      cmd_update "$@" ;;
      backup-info) cmd_backup_info "$@" ;;
      help|--help|-h) cmd_help ;;
      *) err "Comando desconhecido: $COMMAND"; cmd_help; exit 1 ;;
    esac
  ''
