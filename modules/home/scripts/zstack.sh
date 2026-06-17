#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar # Ativa a busca recursiva com ** para o age

# zstack — Gerenciador de Docker Stacks e Secrets para ZaneyOS Homelab
# Uso: zstack <comando> [argumentos]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

STACKS_ROOT="$HOME/zaneyos/docker/stacks"
AGE_KEY_FILE="$HOME/zaneyos/.age/key.txt"

info()    { echo -e "${CYAN}ℹ${NC}  $*"; }
ok()      { echo -e "${GREEN}✔${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
err()     { echo -e "${RED}✘${NC}  $*" >&2; }
die()     { err "$*"; exit 1; }
section() { echo -e "\n${BLUE}━━ $* ━━${NC}"; }

# ─── Password Generators ─────────────────────────────────────────────────

genpass() {
  local len="${1:-24}"
  openssl rand -base64 $((len + 8)) | tr -dc 'A-Za-z0-9_@#%+=.!-' | head -c "$len"
  echo
}

genpass_hex() {
  local len="${1:-32}"
  openssl rand -hex "$len"
}

genpass_mssql() {
  local len="${1:-16}"
  local chars='A-Za-z0-9_@#%+=.!-'
  local pass
  while true; do
    pass=$(openssl rand -base64 $((len + 8)) | tr -dc "$chars" | head -c "$len")
    [[ "$pass" =~ [A-Z] && "$pass" =~ [a-z] && "$pass" =~ [0-9] && "$pass" =~ [_@#%+=.\!-] ]] && break
  done
  printf '%s\n' "$pass"
}

gen_htpasswd() {
  local password="$1"
  if command -v htpasswd &>/dev/null; then
    htpasswd -nbB admin "$password" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# ─── Password Field Registry ─────────────────────────────────────────────
# Format: "VARIABLE|relative/stack/path|generator|length|description"
# Generator: pass, hex, mssql, manual
# Use length=0 for manual fields.

declare -a PASSWORD_FIELDS=(
  "POSTGRES_PASSWORD|databases/postgres|pass|32|Postgres password"
  "MYSQL_ROOT_PASSWORD|databases/mysql|pass|32|MySQL root password"
  "MYSQL_PASSWORD|databases/mysql|pass|32|MySQL dev password"
  "REDIS_PASSWORD|databases/redis|pass|32|Redis password"
  "MSSQL_SA_PASSWORD|databases/sqlserver|mssql|16|SQL Server SA password"
  "N8N_BASIC_AUTH_PASSWORD|automation/n8n|pass|32|n8n basic auth password"
  "N8N_ENCRYPTION_KEY|automation/n8n|hex|32|n8n encryption key (hex)"
  "POSTGRES_PASSWORD|automation/n8n|pass|32|n8n Postgres password"
  "WOODPECKER_AGENT_SECRET|automation/woodpecker|hex|32|Woodpecker agent secret (hex)"
  "WOODPECKER_GITHUB_CLIENT|automation/woodpecker|manual|0|GitHub OAuth Client ID"
  "WOODPECKER_GITHUB_SECRET|automation/woodpecker|manual|0|GitHub OAuth Client Secret"
  "ADMIN_PASSWORD|homelab/technitium-dns|pass|32|Technitium DNS admin password"
  "GF_ADMIN_PASSWORD|monitoring/grafana|pass|24|Grafana admin password"
  "MINIO_ROOT_PASSWORD|storage/minio|pass|32|MinIO root password"
)

# ─── Helpers ──────────────────────────────────────────────────────────────

find_compose() {
  local dir="$1"
  if [[ -f "$dir/compose.yml" ]]; then echo "$dir/compose.yml"
  elif [[ -f "$dir/docker-compose.yml" ]]; then echo "$dir/docker-compose.yml"
  else echo ""
  fi
}

resolve_stack_dir() {
  local arg="$1"
  local dir="$STACKS_ROOT/$arg"
  [[ -d "$dir" ]] || die "Stack não encontrada: $arg (procurado em $dir)"
  echo "$dir"
}

run_compose() {
  local dir="$1"; shift
  local compose_file
  compose_file="$(find_compose "$dir")"
  [[ -n "$compose_file" ]] || die "Nenhum compose.yml encontrado em: $dir"
  (cd "$dir" && docker compose -f "$(basename "$compose_file")" "$@")
}

collect_stack_dirs() {
  local target="${1:-}"
  local -n _out=$2

  if [[ -z "$target" ]]; then
    for cat_dir in "$STACKS_ROOT"/*/; do
      [[ -d "$cat_dir" ]] || continue
      for stack_dir in "$cat_dir"/*/; do
        [[ -d "$stack_dir" ]] || continue
        _out+=("$stack_dir")
      done
    done
  elif [[ "$target" == */* ]]; then
    _out+=("$(resolve_stack_dir "$target")")
  else
    local cat_dir="$STACKS_ROOT/$target"
    [[ -d "$cat_dir" ]] || die "Categoria não encontrada: $target"
    for stack_dir in "$cat_dir"/*/; do
      [[ -d "$stack_dir" ]] || continue
      _out+=("$stack_dir")
    done
  fi
}

# ─── INIT ────────────────────────────────────────────────────────────────

cmd_init() {
  local target="${1:-}"
  local force=""

  # Parse args
  if [[ "$target" == "--force" ]]; then
    force="--force"
    target=""
  elif [[ -n "$target" ]]; then
    local second="${2:-}"
    [[ "$second" == "--force" ]] && force="--force"
  fi

  local -a stack_dirs=()
  collect_stack_dirs "$target" stack_dirs

  [[ ${#stack_dirs[@]} -eq 0 ]] && die "Nenhuma stack encontrada para inicializar."

  section "Gerando arquivos .env com senhas fortes"

  local created=0 skipped=0

  for stack_dir in "${stack_dirs[@]}"; do
    local rel_path="${stack_dir#$STACKS_ROOT/}"
    rel_path="${rel_path%/}" # Remove a barra final para comparar certinho com o PASSWORD_FIELDS
    
    local env_example="$stack_dir/.env.example"
    local env_file="$stack_dir/.env"

    # Skip stacks without .env.example
    if [[ ! -f "$env_example" ]]; then
      # warn "Pulando $rel_path: .env.example não encontrado"
      continue
    fi

    # Skip existing .env unless --force
    if [[ -f "$env_file" && "$force" != "--force" ]]; then
      info "$rel_path: .env já existe — pulando (use --force para sobrescrever)"
      ((skipped++)) || true
      continue
    fi

    # Copy .env.example as base
    cp "$env_example" "$env_file"
    chmod 0600 "$env_file"

    # Replace placeholder password fields
    local has_passwords=false
    for entry in "${PASSWORD_FIELDS[@]}"; do
      IFS='|' read -r varname field_stack gen len desc <<< "$entry"
      [[ "$rel_path" == "$field_stack" ]] || continue

      local value=""
      case "$gen" in
        pass)   value=$(genpass "$len") ;;
        hex)    value=$(genpass_hex "$len") ;;
        mssql)  value=$(genpass_mssql "$len") ;;
        manual)
          echo -en "  ${CYAN}${desc}${NC} (${YELLOW}${varname}${NC}): "
          read -r value
          ;;
      esac

      if grep -q "^${varname}=" "$env_file"; then
        sed -i "s|^${varname}=.*|${varname}=${value}|" "$env_file"
        ok "  $rel_path: $varname = ${value:0:8}..."
        has_passwords=true
      fi
    done

    if [[ "$has_passwords" == true ]]; then
      ok "$rel_path: .env criado com senhas"
    else
      ok "$rel_path: .env criado (sem senhas)"
    fi
    ((created++)) || true
  done

  echo ""
  ok "Criados: $created | Pulados (já existiam): $skipped"
  info "Revise os .env em $STACKS_ROOT antes de rodar 'zstack up'."
}

# ─── ENCRYPT / DECRYPT (age) ─────────────────────────────────────────────

cmd_encrypt() {
  local target="${1:-}"
  command -v age &>/dev/null || die "'age' não encontrado. Instale com o NixOS (modules/core/packages.nix)"

  # Ensure age key exists
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    section "Configurando Age key"
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    chmod 0700 "$(dirname "$AGE_KEY_FILE")"
    age-keygen -o "$AGE_KEY_FILE" 2>/dev/null
    chmod 0600 "$AGE_KEY_FILE"
    ok "Age key gerada: $AGE_KEY_FILE"
    local pubkey
    pubkey=$(age-keygen -y "$AGE_KEY_FILE")
    info "Pubkey: $pubkey"
    echo ""
  fi

  local -a env_files=()
  if [[ -z "$target" ]]; then
    for env_file in "$STACKS_ROOT"/**/.env; do
      [[ -f "$env_file" ]] && env_files+=("$env_file")
    done
  else
    local stack_dir
    stack_dir="$(resolve_stack_dir "$target")"
    [[ -f "$stack_dir/.env" ]] || die "Não encontrado: $stack_dir/.env"
    env_files+=("$stack_dir/.env")
  fi

  [[ ${#env_files[@]} -eq 0 ]] && die "Nenhum .env encontrado para criptografar."

  section "Criptografando .env files com age"

  for env_file in "${env_files[@]}"; do
    local enc_file="${env_file}.age"
    age --encrypt -i "$AGE_KEY_FILE" -o "$enc_file" "$env_file"
    chmod 0600 "$enc_file"
    ok "Criptografado: $enc_file"
  done

  echo ""
  ok "Pronto. Para descriptografar: zstack decrypt $target"
}

cmd_decrypt() {
  local target="${1:-}"
  command -v age &>/dev/null || die "'age' não encontrado."
  [[ -f "$AGE_KEY_FILE" ]] || die "Age key não encontrada: $AGE_KEY_FILE"

  local -a enc_files=()
  if [[ -z "$target" ]]; then
    for enc_file in "$STACKS_ROOT"/**/.env.age; do
      [[ -f "$enc_file" ]] && enc_files+=("$enc_file")
    done
  else
    local stack_dir
    stack_dir="$(resolve_stack_dir "$target")"
    local enc_file="$stack_dir/.env.age"
    [[ -f "$enc_file" ]] || die "Não encontrado: $enc_file"
    enc_files+=("$enc_file")
  fi

  [[ ${#enc_files[@]} -eq 0 ]] && die "Nenhum .env.age encontrado para descriptografar."

  section "Descriptografando .env.age files"

  for enc_file in "${enc_files[@]}"; do
    local env_file="${enc_file%.age}"
    age --decrypt -i "$AGE_KEY_FILE" -o "$env_file" "$enc_file"
    chmod 0600 "$env_file"
    ok "Descriptografado: $env_file"
  done
}

# ─── STACKS ───────────────────────────────────────────────────────────────

cmd_list() {
  local category=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --category|-c) shift; category="$1"; shift ;;
      *) die "Argumento desconhecido: $1" ;;
    esac
  done

  [[ -d "$STACKS_ROOT" ]] || die "Diretório de stacks não encontrado: $STACKS_ROOT"
  section "Stacks disponíveis"

  list_category() {
    local cat_dir="$1"
    local cat
    cat="$(basename "$cat_dir")"
    echo -e "${CYAN}$cat/${NC}"

    local root_compose
    root_compose="$(find_compose "$cat_dir")"
    if [[ -n "$root_compose" ]]; then
      local has_env=""
      if [[ -f "$cat_dir/.env" ]]; then
        has_env="${GREEN}[.env OK]${NC}"
      else
        has_env="${YELLOW}[sem .env — rode: zstack init]${NC}"
      fi
      echo -e "  ├─ ${BLUE}[ROOT]${NC}  ${GREEN}[compose]${NC}  $has_env  → zstack up $cat"
    fi

    for stack_dir in "$cat_dir"/*/; do
      [[ -d "$stack_dir" ]] || continue
      local stack
      stack="$(basename "$stack_dir")"
      local compose_file
      compose_file="$(find_compose "$stack_dir")"
      local has_env=""
      [[ -f "$stack_dir/.env" ]] && has_env="${GREEN}[.env OK]${NC}" || has_env="${YELLOW}[sem .env]${NC}"
      local has_compose=""
      [[ -n "$compose_file" ]] && has_compose="${GREEN}[compose]${NC}" || has_compose="${RED}[sem compose]${NC}"
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

cmd_up() {
  [[ $# -ge 1 ]] || die "Uso: zstack up <categoria>|<categoria/stack>"
  local stack_dir
  stack_dir="$(resolve_stack_dir "$1")"
  section "Subindo $1"
  run_compose "$stack_dir" up -d
  ok "Stack $1 iniciada."
}

cmd_down() {
  [[ $# -ge 1 ]] || die "Uso: zstack down <categoria>|<categoria/stack>"
  local stack_dir
  stack_dir="$(resolve_stack_dir "$1")"
  section "Derrubando $1"
  run_compose "$stack_dir" down
  ok "Stack $1 parada."
}

cmd_restart() {
  [[ $# -ge 1 ]] || die "Uso: zstack restart <categoria>|<categoria/stack>"
  local stack_dir
  stack_dir="$(resolve_stack_dir "$1")"
  section "Reiniciando $1"
  run_compose "$stack_dir" down
  run_compose "$stack_dir" up -d
  ok "Stack $1 reiniciada."
}

cmd_logs() {
  [[ $# -ge 1 ]] || die "Uso: zstack logs <categoria>|<categoria/stack>"
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

    local root_compose
    root_compose="$(find_compose "$cat_dir")"
    if [[ -n "$root_compose" ]]; then
      found=1
      echo -e "\n${BLUE}$cat [ROOT]${NC}"
      (cd "$cat_dir" && docker compose ps --format table 2>/dev/null) || true
    fi

    for stack_dir in "$cat_dir"/*/; do
      [[ -d "$stack_dir" ]] || continue
      local stack
      stack="$(basename "$stack_dir")"
      local compose_file
      compose_file="$(find_compose "$stack_dir")"
      [[ -n "$compose_file" ]] || continue
      found=1
      echo -e "\n${CYAN}$cat/$stack${NC}"
      (cd "$stack_dir" && docker compose ps --format table 2>/dev/null) || true
    done
  done
  [[ $found -eq 1 ]] || warn "Nenhuma stack com compose encontrada"
}

cmd_doctor() {
  section "Diagnóstico"
  local ok_count=0 warn_count=0
  check() { if "$@" &>/dev/null; then ok "$1"; ((ok_count++)) || true; else err "$1"; ((warn_count++)) || true; fi; }
  check "Docker instalado" command -v docker
  check "Docker Compose" docker compose version
  check "Docker daemon" docker info
  check "Diretório stacks" test -d "$STACKS_ROOT"
  echo ""
  ok "OK: $ok_count"
  [[ $warn_count -gt 0 ]] && warn "Avisos: $warn_count"
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

cmd_help() {
  cat <<'HELP'
zstack — Gerenciador de Docker Stacks e Secrets para ZaneyOS Homelab

Stack:
  zstack list [--cat <cat>]              Listar stacks
  zstack init [<cat>] [--force]         Criar .env com senhas aleatórias
  zstack up   <cat>|<cat/stack>         Subir
  zstack down <cat>|<cat/stack>         Derrubar
  zstack restart <cat>|<cat/stack>      Reiniciar
  zstack logs  <cat>|<cat/stack>        Logs
  zstack ps                             Status
  zstack doctor                         Diagnóstico
  zstack update <cat/stack>             Atualizar imagens

Secrets (age encryption):
  zstack encrypt [<cat/stack>]          Criptografar .env com age
  zstack decrypt [<cat/stack>]          Descriptografar .env.age com age

Exemplos:
  zstack init              # gera todos os .env com senhas fortes
  zstack init databases    # gera apenas .env de databases/
  zstack init --force      # regenera todos os .env (sobrescreve)
  zstack encrypt           # criptografa todos os .env com age
  zstack up databases      # sobe as stacks de database
HELP
}

# ─── MAIN ─────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"
shift 2>/dev/null || true

case "$COMMAND" in
  list)              cmd_list "$@" ;;
  init)              cmd_init "$@" ;;
  up)                cmd_up "$@" ;;
  down)              cmd_down "$@" ;;
  restart)           cmd_restart "$@" ;;
  logs)              cmd_logs "$@" ;;
  ps)                cmd_ps "$@" ;;
  doctor)            cmd_doctor "$@" ;;
  update)            cmd_update "$@" ;;
  encrypt)           cmd_encrypt "$@" ;;
  decrypt)           cmd_decrypt "$@" ;;
  help|--help|-h)    cmd_help ;;
  *) err "Comando desconhecido: $COMMAND"; cmd_help; exit 1 ;;
esac