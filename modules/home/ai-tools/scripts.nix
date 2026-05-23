# AI Tools — CLI scripts (Home Manager)
# Provides: ai-env-check, ai-openrouter-check, ai-tools-list,
#           ai-models-help, ai-path-check
{pkgs, ...}: let
  # Helper: show first N chars of a secret, rest masked
  maskSecret = ''
    _mask_secret() {
      local val="$1" n="''${2:-8}"
      if [ -z "$val" ]; then echo "(não definido)"; return; fi
      local shown="''${val:0:$n}"
      echo "''${shown}..."
    }
  '';

  # All tools to check in PATH
  aiTools = [
    {bin = "claude"; label = "Claude Code"; editions = "vm+";}
    {bin = "codex"; label = "Codex CLI"; editions = "vm+";}
    {bin = "copilot"; label = "GitHub Copilot CLI"; editions = "vm+";}
    {bin = "qwen"; label = "Qwen Code"; editions = "basic+";}
    {bin = "mods"; label = "mods (charm)"; editions = "basic+";}
    {bin = "opencode"; label = "OpenCode"; editions = "medium+";}
    {bin = "aider"; label = "Aider"; editions = "medium+";}
    {bin = "goose"; label = "Goose CLI"; editions = "medium+";}
    {bin = "gemini"; label = "Gemini CLI"; editions = "medium+";}
    {bin = "sgpt"; label = "shell-gpt"; editions = "medium+";}
    {bin = "aichat"; label = "aichat"; editions = "full";}
    {bin = "ollama"; label = "Ollama"; editions = "full";}
    {bin = "llama-cli"; label = "llama.cpp"; editions = "full";}
    {bin = "hermes"; label = "Hermes Agent"; editions = "basic+ (manual)";}
  ];

  checkToolsScript = builtins.concatStringsSep "\n" (map (t: ''
    if command -v ${builtins.head (builtins.split " " t.bin)} &>/dev/null; then
      _ver=$(${t.bin} --version 2>/dev/null | head -1 || echo "?")
      ok "${t.label} [${t.editions}]  ($_ver)"
    else
      warn "${t.label} [${t.editions}]: não instalado"
    fi
  '') aiTools);

in {
  home.packages = [
    # ── ai-env-check ────────────────────────────────────────────────────────
    (pkgs.writeShellScriptBin "ai-env-check" ''
      #!/usr/bin/env bash
      set -euo pipefail

      ${maskSecret}

      GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
      PASS=0; WARN=0; FAIL=0
      ok()   { echo -e "  ''${GREEN}✓''${NC} $1"; PASS=$((PASS+1)); }
      warn() { echo -e "  ''${YELLOW}⚠''${NC}  $1"; WARN=$((WARN+1)); }
      fail() { echo -e "  ''${RED}✗''${NC} $1"; FAIL=$((FAIL+1)); }
      hint() { echo -e "       ''${YELLOW}→ $1''${NC}"; }
      section() { echo -e "\n''${CYAN}''${BOLD}━━━ $1 ━━━''${NC}"; }

      echo -e "\n''${CYAN}''${BOLD}╔══════════════════════════════════════════════╗''${NC}"
      echo -e "''${CYAN}''${BOLD}║  AI Tools — Verificação de Ambiente           ║''${NC}"
      echo -e "''${CYAN}''${BOLD}╚══════════════════════════════════════════════╝''${NC}"

      section "Arquivo de Configuração"
      ENV_FILE="$HOME/.config/ai-tools/openrouter.env"
      if [ -f "$ENV_FILE" ]; then
        ok "Arquivo encontrado: $ENV_FILE"
      else
        fail "Arquivo não encontrado: $ENV_FILE"
        hint "cp $(nix eval --raw nixpkgs#my-zaneyos 2>/dev/null || echo '~/zaneyos')/docs/examples/openrouter.env.example $ENV_FILE"
        hint "Edite o arquivo e defina suas chaves"
        echo ""
        echo -e "''${YELLOW}  Crie o arquivo com:''${NC}"
        echo "  mkdir -p ~/.config/ai-tools"
        echo "  cat > ~/.config/ai-tools/openrouter.env << 'EOF'"
        echo '  export OPENROUTER_API_KEY="sk-or-..."'
        echo '  export ANTHROPIC_BASE_URL="https://openrouter.ai/api"'
        echo '  export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"'
        echo '  export ANTHROPIC_API_KEY=""'
        echo "  EOF"
      fi

      section "Variáveis de Ambiente"
      if [ -n "''${OPENROUTER_API_KEY:-}" ]; then
        ok "OPENROUTER_API_KEY = $(_mask_secret "$OPENROUTER_API_KEY")"
      else
        fail "OPENROUTER_API_KEY não definido"
        hint "source ~/.config/ai-tools/openrouter.env  (depois abra novo terminal)"
      fi

      if [ "''${ANTHROPIC_BASE_URL:-}" = "https://openrouter.ai/api" ]; then
        ok "ANTHROPIC_BASE_URL = https://openrouter.ai/api"
      elif [ -z "''${ANTHROPIC_BASE_URL:-}" ]; then
        warn "ANTHROPIC_BASE_URL não definido (Claude Code usará Anthropic diretamente)"
        hint "export ANTHROPIC_BASE_URL=\"https://openrouter.ai/api\""
      else
        warn "ANTHROPIC_BASE_URL = ''${ANTHROPIC_BASE_URL} (esperado: https://openrouter.ai/api)"
      fi

      if [ -n "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
        ok "ANTHROPIC_AUTH_TOKEN = $(_mask_secret "$ANTHROPIC_AUTH_TOKEN")"
      else
        warn "ANTHROPIC_AUTH_TOKEN não definido (necessário para Claude Code via OpenRouter)"
        hint "export ANTHROPIC_AUTH_TOKEN=\"\$OPENROUTER_API_KEY\""
      fi

      if [ -z "''${ANTHROPIC_API_KEY:-}" ]; then
        ok "ANTHROPIC_API_KEY = (vazio — correto para OpenRouter)"
      else
        warn "ANTHROPIC_API_KEY está definido (pode conflitar com OpenRouter routing)"
        hint "export ANTHROPIC_API_KEY=\"\"  (deve ser explicitamente vazio)"
      fi

      section "Ferramentas no PATH"
      for tool in claude codex copilot qwen mods opencode aider goose gemini sgpt aichat ollama; do
        if command -v "$tool" &>/dev/null; then
          ok "$tool  ($(command -v "$tool"))"
        else
          warn "$tool: não encontrado no PATH"
        fi
      done
      # hermes (instalação manual)
      if command -v hermes &>/dev/null; then
        ok "hermes"
      else
        warn "hermes: não encontrado (instalação manual necessária)"
        hint "Ver docs/ai-tools.md — seção Hermes Agent"
      fi

      echo -e "\n''${CYAN}''${BOLD}━━━ Sumário ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
      echo -e "  ''${GREEN}✓ Passou : $PASS''${NC}  ''${YELLOW}⚠ Avisos : $WARN''${NC}  ''${RED}✗ Falhou : $FAIL''${NC}"
      [ "$FAIL" -gt 0 ] && echo -e "\n''${RED}❌ Corrija as falhas acima e execute: source ~/.config/ai-tools/openrouter.env''${NC}"
      [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ] && echo -e "\n''${GREEN}🎉 Ambiente de IA configurado corretamente!''${NC}"
      echo ""
    '')

    # ── ai-openrouter-check ──────────────────────────────────────────────────
    (pkgs.writeShellScriptBin "ai-openrouter-check" ''
      #!/usr/bin/env bash
      set -euo pipefail

      GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

      echo -e "\n''${YELLOW}Testando conectividade com OpenRouter...''${NC}"

      if [ -z "''${OPENROUTER_API_KEY:-}" ]; then
        echo -e "''${RED}✗ OPENROUTER_API_KEY não definido. Execute: source ~/.config/ai-tools/openrouter.env''${NC}"
        exit 1
      fi

      RESPONSE=$(curl -sf \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        https://openrouter.ai/api/v1/models 2>&1) || {
        echo -e "''${RED}✗ Falha ao conectar em openrouter.ai/api/v1/models''${NC}"
        echo "   Verifique sua chave e conexão com a internet."
        exit 1
      }

      MODEL_COUNT=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq '.data | length' 2>/dev/null || echo "?")
      echo -e "''${GREEN}✓ OpenRouter acessível — $MODEL_COUNT modelos disponíveis''${NC}"
      echo ""
      echo "Modelos de coding recomendados:"
      echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.data[].id' 2>/dev/null \
        | grep -Ei "claude|gpt|codex|qwen|deepseek|gemini" \
        | sort | head -20 || true
    '')

    # ── ai-tools-list ────────────────────────────────────────────────────────
    (pkgs.writeShellScriptBin "ai-tools-list" ''
      #!/usr/bin/env bash
      set -euo pipefail

      CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

      echo -e "\n''${CYAN}''${BOLD}━━━ AI Tools instalados neste sistema ━━━''${NC}\n"

      _check() {
        local bin="$1" label="$2" editions="$3"
        if command -v "$bin" &>/dev/null; then
          local ver
          ver=$("$bin" --version 2>/dev/null | head -1 || echo "?")
          echo -e "  ''${GREEN}✓''${NC} ''${BOLD}$label''${NC}  [$editions]\n     $(command -v "$bin")\n     $ver"
        else
          echo -e "  ''${YELLOW}–''${NC} $label  [$editions]: não instalado nesta edição"
        fi
        echo ""
      }

      _check claude      "Claude Code"          "vm+"
      _check codex       "Codex CLI"            "vm+"
      _check copilot     "GitHub Copilot CLI"   "vm+"
      _check qwen        "Qwen Code"            "basic+"
      _check mods        "mods (charm)"         "basic+"
      _check opencode    "OpenCode"             "medium+"
      _check aider       "Aider"                "medium+"
      _check goose       "Goose CLI"            "medium+"
      _check gemini      "Gemini CLI"           "medium+"
      _check sgpt        "shell-gpt"            "medium+"
      _check aichat      "aichat"               "full"
      _check ollama      "Ollama"               "full"
      _check llama-cli   "llama.cpp"            "full"
      _check hermes      "Hermes Agent"         "manual"

      echo -e "  ''${YELLOW}ℹ''${NC}  Para configurar OpenRouter: ai-env-check"
      echo -e "  ''${YELLOW}ℹ''${NC}  Autenticar Copilot: copilot auth login"
      echo ""
    '')

    # ── ai-models-help ───────────────────────────────────────────────────────
    (pkgs.writeShellScriptBin "ai-models-help" ''
      #!/usr/bin/env bash
      CYAN='\033[0;36m'; BOLD='\033[1m'; YELLOW='\033[1;33m'; NC='\033[0m'

      echo -e "\n''${CYAN}''${BOLD}━━━ Modelos recomendados por ferramenta ━━━''${NC}\n"

      echo -e "''${BOLD}Claude Code (via OpenRouter):''${NC}"
      echo "  ~anthropic/claude-opus-latest      (máximo, mais lento)"
      echo "  ~anthropic/claude-sonnet-latest    (balanceado ✓ recomendado)"
      echo "  ~anthropic/claude-haiku-latest     (rápido, tarefas simples)"
      echo ""
      echo -e "''${BOLD}Codex CLI (~/.codex/config.toml):''${NC}"
      echo '  model = "~openai/gpt-latest"'
      echo '  model = "~anthropic/claude-sonnet-latest"'
      echo ""
      echo -e "''${BOLD}Aider:''${NC}"
      echo "  aider --model openrouter/anthropic/claude-sonnet-4-5"
      echo "  aider --model openrouter/deepseek/deepseek-coder"
      echo ""
      echo -e "''${BOLD}Ollama (modelos locais — edição Full):''${NC}"
      echo "  ollama pull llama3"
      echo "  ollama pull codellama"
      echo "  ollama pull qwen2.5-coder"
      echo "  ollama pull deepseek-coder-v2"
      echo "  (modelos em ~/.ollama/models — pode ocupar vários GB)"
      echo ""
      echo -e "''${YELLOW}Documentação completa: ~/zaneyos/docs/ai-tools-openrouter.md''${NC}"
      echo ""
    '')

    # ── ai-path-check ────────────────────────────────────────────────────────
    (pkgs.writeShellScriptBin "ai-path-check" ''
      #!/usr/bin/env bash
      GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
      echo ""
      for tool in claude codex copilot qwen mods opencode aider goose gemini sgpt aichat ollama llama-cli hermes; do
        if command -v "$tool" &>/dev/null; then
          echo -e "  ''${GREEN}✓''${NC} $tool → $(command -v "$tool")"
        else
          echo -e "  ''${YELLOW}–''${NC} $tool  (não instalado)"
        fi
      done
      echo ""
    '')
  ];
}
