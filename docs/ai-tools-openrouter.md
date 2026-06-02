# OpenRouter — Configuração Completa

OpenRouter permite usar múltiplos provedores de LLM com uma única chave de API.
Use com qualquer ferramenta de IA instalada no ZaneyOS.

---

## Configuração do arquivo de ambiente

**Nunca coloque chaves de API em arquivos `.nix`, no Git ou no `/nix/store`.**

### 1. Crie o arquivo de configuração

```bash
mkdir -p ~/.config/ai-tools
cp ~/zaneyos/docs/examples/openrouter.env.example ~/.config/ai-tools/openrouter.env
```

### 2. Edite e preencha sua chave

```bash
# Obtenha sua chave em: https://openrouter.ai/settings/keys
nano ~/.config/ai-tools/openrouter.env
```

Conteúdo mínimo:

```bash
export OPENROUTER_API_KEY="sk-or-SUA_CHAVE_AQUI"
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""
```

### 3. O arquivo é carregado automaticamente

O shell (zsh/fish) carrega `~/.config/ai-tools/openrouter.env` a cada login.
Abra um novo terminal ou execute:

```bash
source ~/.config/ai-tools/openrouter.env
```

### 4. Valide

```bash
ai-env-check
ai-openrouter-check
```

---

## Claude Code via OpenRouter

```bash
claude
claude /status   # deve mostrar OpenRouter + base URL
```

Se você já teve sessão Anthropic anterior:

```bash
claude /logout   # remove sessão cacheada
# feche e reabra o terminal
claude           # nova sessão via OpenRouter
```

---

## Codex CLI via OpenRouter

Config em `~/.codex/config.toml` (criado automaticamente):

```toml
model_provider = "openrouter"
model = "~anthropic/claude-sonnet-latest"

[model_providers.openrouter]
name = "openrouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
```

---

## OpenCode via OpenRouter

```bash
opencode         # inicia
/connect         # selecione: OpenRouter
/models          # escolha o modelo
```

Ou via `opencode.json` no diretório do projeto:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "openrouter": {
      "models": {
        "~anthropic/claude-sonnet-latest": {},
        "~google/gemini-flash-latest": {}
      }
    }
  }
}
```

---

## Hermes Agent via OpenRouter

```bash
# Selecionar provider interativamente
hermes model

# Ou configurar diretamente
hermes config set OPENROUTER_API_KEY "$OPENROUTER_API_KEY"
hermes chat --provider openrouter --model '~anthropic/claude-sonnet-latest'
```

Arquivos de config (não versionados):
- `~/.hermes/.env` — chaves secretas
- `~/.hermes/config.yaml` — provider e modelo (criado automaticamente)

---

## Aider via OpenRouter

```bash
aider --model openrouter/anthropic/claude-sonnet-4-5
aider --model openrouter/deepseek/deepseek-coder
aider --model openrouter/openai/gpt-4o
```

---

## Formatos de modelo no OpenRouter

| Formato | Descrição |
|---|---|
| `~anthropic/claude-sonnet-latest` | Última versão da família (recomendado) |
| `anthropic/claude-sonnet-4-5` | Versão específica |
| `openrouter/auto` | OpenRouter escolhe o melhor modelo para o prompt |
| `deepseek/deepseek-coder` | Acesso direto a modelos open-source |

---

## Segurança

- ✅ Chave em `~/.config/ai-tools/openrouter.env` (fora do repo)
- ✅ Arquivo no `.gitignore`
- ✅ `ANTHROPIC_API_KEY=""` explicitamente vazio
- ❌ Nunca em `variables.nix`, `flake.nix`, `configuration.nix`
- ❌ Nunca em qualquer arquivo `.nix` (vai para `/nix/store`)
- ❌ Nunca em arquivos `.env` dentro do repo
