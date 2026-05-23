# AI Tools — Guia de Ferramentas por Edição

As ferramentas de IA são integradas ao sistema de edições existente do ZaneyOS.
Cada edição é **aditiva**: `full` inclui tudo do `medium`, que inclui tudo do `basic`.

---

## Scripts disponíveis em todas as edições

Após o rebuild, os seguintes scripts estão disponíveis no PATH:

| Script | Descrição |
|---|---|
| `ai-env-check` | Valida variáveis de ambiente e ferramentas no PATH |
| `ai-openrouter-check` | Testa conectividade com a API do OpenRouter |
| `ai-tools-list` | Lista ferramentas instaladas e suas versões |
| `ai-models-help` | Modelos recomendados por ferramenta |
| `ai-path-check` | Verifica quais ferramentas estão no PATH |

---

## Matriz de IA por edição

| Recurso | VM | Basic | Medium | Full |
|---|:---:|:---:|:---:|:---:|
| OpenRouter env support | ✅ | ✅ | ✅ | ✅ |
| ai-env-check / ai-tools-list / ai-path-check | ✅ | ✅ | ✅ | ✅ |
| **Claude Code** | ✅ | ✅ | ✅ | ✅ |
| **Codex CLI** | ✅ | ✅ | ✅ | ✅ |
| **GitHub Copilot CLI** (`copilot`) | ✅ | ✅ | ✅ | ✅ |
| **Qwen Code** | ❌ | ✅ | ✅ | ✅ |
| **mods** (charm, pipe-friendly) | ❌ | ✅ | ✅ | ✅ |
| Hermes Agent | ❌ | TODO¹ | TODO¹ | TODO¹ |
| **OpenCode** | ❌ | ❌ | ✅ | ✅ |
| **Aider** | ❌ | ❌ | ✅ | ✅ |
| **Goose CLI** | ❌ | ❌ | ✅ | ✅ |
| **Gemini CLI** | ❌ | ❌ | ✅ | ✅ |
| **shell-gpt** | ❌ | ❌ | ✅ | ✅ |
| **aichat** | ❌ | ❌ | ❌ | ✅ |
| **llama.cpp** | ❌ | ❌ | ❌ | ✅ |
| opencode-desktop (GUI) | ❌ | ❌ | ❌ | ✅ |
| Ollama (serviço NixOS) | ❌ | ❌ | ❌ | opt |
| Open WebUI (Docker stack) | ❌ | ❌ | ❌ | opt |
| Tabby (self-hosted completion) | ❌ | ❌ | ❌ | opt |

¹ **Hermes Agent** não está no nixpkgs. Consulte:
- https://github.com/NousResearch/hermes-agent
- Após instalar: `hermes model` → selecione OpenRouter

² **opencode-desktop** disponível no nixpkgs unstable desde 2026-05 (v1.15.7+).
Instalado na edição **full** via `modules/ai-tools/tier3.nix`.
O CLI `opencode` já está na edição **medium** (tier2).

---

## Configuração por ferramenta

### GitHub Copilot CLI (vm+)

Instalado via `github-copilot-cli` do nixpkgs. Binário: `copilot` (standalone, **não** é `gh extension`).

```bash
# Autenticar (necessário uma vez)
copilot auth login

# Usar
copilot suggest "crie um script bash que..."
copilot explain "o que faz este comando: ls -la"
copilot --version
```

---

### Claude Code (basic+)

```bash
# Verificar status
claude /status   # deve mostrar OpenRouter/base URL

# Se precisar fazer logout de sessão Anthropic anterior
claude /logout
```

**Variáveis necessárias** (definidas em `~/.config/ai-tools/openrouter.env`):
```bash
ANTHROPIC_BASE_URL="https://openrouter.ai/api"
ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
ANTHROPIC_API_KEY=""   # deve ser explicitamente vazio
```

---

### Codex CLI (basic+)

Config em `~/.codex/config.toml` (criado automaticamente pelo Home Manager):

```toml
model_provider = "openrouter"
model = "~anthropic/claude-sonnet-latest"

[model_providers.openrouter]
name = "openrouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
```

```bash
codex            # inicia sessão interativa
codex "..."      # prompt direto
```

---

### Qwen Code (basic+)

```bash
qwen             # inicia no diretório do projeto
```

Usa `OPENROUTER_API_KEY` automaticamente via OpenRouter.

---

### mods — AI no terminal (basic+)

```bash
echo "explique este erro" | mods
git diff | mods "escreva uma mensagem de commit"
mods "o que faz este comando: $(cat script.sh)"
```

---

### OpenCode (medium+)

```bash
opencode         # inicia no diretório do projeto
/connect         # selecione OpenRouter
/models          # escolha o modelo
```

---

### Aider (medium+)

```bash
# Com OpenRouter
aider --model openrouter/anthropic/claude-sonnet-4-5
aider --model openrouter/deepseek/deepseek-coder

# Ou via variável
OPENROUTER_API_KEY=sk-or-... aider --model openrouter/...
```

---

### Goose CLI (medium+)

```bash
goose session    # inicia sessão interativa
goose run        # executa tarefa específica
```

---

### Gemini CLI (medium+)

```bash
gemini                              # inicia interativo (usa GOOGLE_API_KEY ou OpenRouter)
gemini -p "explique este código"    # prompt direto
```

---

### shell-gpt (medium+)

```bash
sgpt "escreva um one-liner bash para..."
sgpt --shell "liste os 10 arquivos mais grandes"
sgpt --code "função Python que..."
```

---

### Ollama (full — opcional)

```bash
# Ativar serviço em modules/editions/full.nix:
# services.ollama.enable = true;
# Depois: zcli rebuild

ollama pull llama3
ollama pull codellama
ollama pull qwen2.5-coder
ollama pull deepseek-coder-v2
ollama run codellama
```

---

## Testar ambiente

```bash
ai-env-check           # valida vars de ambiente + ferramentas no PATH
ai-openrouter-check    # testa conectividade com OpenRouter (requer chave)
ai-tools-list          # lista todas as ferramentas com versão
ai-models-help         # modelos recomendados por ferramenta
ai-path-check          # check rápido do PATH
```

---

## Rebuild do sistema

```bash
zcli rebuild           # rebuild + ai-env-check automático
```

---

## Riscos conhecidos no NixOS

- **`/bin/bash` hardcoded**: algumas ferramentas (ex: Codex CLI) esperam `/bin/bash`. O NixOS tem `/bin/sh` via `environment.binsh`. Soluções: usar wrapper com `makeWrapper`, ou configurar `programs.bash.enable = true` no Home Manager.
- **Ferramentas Node.js**: Claude Code, Codex e outros requerem Node.js 22+. O nixpkgs empacota com Node bundled, então `node` do sistema não precisa ser compatível.
- **API keys no `/nix/store`**: nunca coloque chaves em arquivos `.nix`. O `/nix/store` é público e legível por todos os usuários do sistema.
