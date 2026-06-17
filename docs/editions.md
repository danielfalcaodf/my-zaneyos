# Guia de Edições — ZaneyOS Custom Fork

As edições definem quais ferramentas, serviços e stacks são instalados no sistema.
A edição é configurada em `hosts/<hostname>/variables.nix` via `edition = "..."`.

---

## Edições disponíveis

| Edição | Caso de uso |
|---|---|
| `vm` | Máquinas virtuais, ambientes de teste leves |
| `basic` | Desktop de desenvolvimento com homelab básico |
| `medium` | Workstation completa: cloud, databases, monitoring |
| `full` | Estação máxima: LLM, Android SDK, todas as ferramentas |

Cada edição é **aditiva**: `full` inclui tudo do `medium`, que inclui tudo do `basic`.

---

## Matriz de recursos por edição

| Recurso | VM | Basic | Medium | Full |
|---|:---:|:---:|:---:|:---:|
| **Desktop & UI** | | | | |
| Desktop Hyprland/ZaneyOS | ✅ | ✅ | ✅ | ✅ |
| Stylix / Waybar / Noctalia | ✅ | ✅ | ✅ | ✅ |
| VS Code (`vscodeEnable`) | ✅ | ✅ | ✅ | ✅ |
| Plymouth boot | ❌ | ✅ | ✅ | ✅ |
| **Homelab** | | | | |
| Docker | opt | ✅ | ✅ | ✅ |
| Caddy (reverse proxy local) | ❌ | ✅ | ✅ | ✅ |
| DNS local (`*.localhost`) | ❌ | ✅ | ✅ | ✅ |
| Secrets (sops-nix + zstack secrets) | ❌ | ✅ | ✅ | ✅ |
| Docker Registry (local) | ❌ | opt | opt | opt |
| **Dev — Node / Python** | | | | |
| Node.js 22 + pnpm | ✅ | ✅ | ✅ | ✅ |
| Python 3 + uv + ruff | ✅ | ✅ | ✅ | ✅ |
| NVM (wrapper shell) | ✅ | ✅ | ✅ | ✅ |
| mise (versão global) | ✅ | ✅ | ✅ | ✅ |
| **Dev — JVM** | | | | |
| JDK 21 + Maven + Gradle | ❌ | ❌ | ✅ | ✅ |
| SDKMAN (wrapper shell) | ❌ | ❌ | ✅ | ✅ |
| **Dev — Ferramentas** | | | | |
| git + lazygit + gh + delta | ✅ | ✅ | ✅ | ✅ |
| just + direnv | ✅ | ✅ | ✅ | ✅ |
| zellij | ❌ | ❌ | ✅ | ✅ |
| pre-commit + lefthook + gitleaks | ❌ | ❌ | ✅ | ✅ |
| **LSPs (editores)** | | | | |
| nil (Nix LSP) | ✅ | ✅ | ✅ | ✅ |
| typescript-language-server | ✅ | ✅ | ✅ | ✅ |
| bash-language-server | ✅ | ✅ | ✅ | ✅ |
| yaml-language-server | ✅ | ✅ | ✅ | ✅ |
| python-lsp-server | ✅ | ✅ | ✅ | ✅ |
| biome | ✅ | ✅ | ✅ | ✅ |
| **Bancos de dados (clientes)** | | | | |
| PostgreSQL client | ❌ | ✅ | ✅ | ✅ |
| MySQL client | ❌ | ❌ | ✅ | ✅ |
| Redis client | ❌ | ❌ | ✅ | ✅ |
| DBeaver | ❌ | ❌ | ✅ | ✅ |
| pspg (pager SQL) | ❌ | ❌ | ✅ | ✅ |
| **Cloud / DevOps** | | | | |
| AWS CLI v2 | ❌ | ❌ | ✅ | ✅ |
| Google Cloud SDK | ❌ | ❌ | ✅ | ✅ |
| Terraform + Terragrunt | ❌ | ❌ | ✅ | ✅ |
| kubectl + k9s + helm | ❌ | ❌ | ✅ | ✅ |
| kubectx + stern + kustomize | ❌ | ❌ | ✅ | ✅ |
| k3d | ❌ | ❌ | ❌ | ✅ |
| Firebase Tools | ❌ | ❌ | ❌ | ✅ |
| **LLM / IA** | | | | |
| OpenRouter env support | ✅ | ✅ | ✅ | ✅ |
| ai-env-check / ai-tools-list | ✅ | ✅ | ✅ | ✅ |
| Claude Code | ✅ | ✅ | ✅ | ✅ |
| Codex CLI | ✅ | ✅ | ✅ | ✅ |
| GitHub Copilot CLI (`copilot`) | ✅ | ✅ | ✅ | ✅ |
| Qwen Code | ❌ | ✅ | ✅ | ✅ |
| mods (charm, pipe AI) | ❌ | ✅ | ✅ | ✅ |
| Hermes Agent | ❌ | TODO¹ | TODO¹ | TODO¹ |
| OpenCode | ❌ | ❌ | ✅ | ✅ |
| Aider | ❌ | ❌ | ✅ | ✅ |
| Goose CLI | ❌ | ❌ | ✅ | ✅ |
| Gemini CLI | ❌ | ❌ | ✅ | ✅ |
| shell-gpt | ❌ | ❌ | ✅ | ✅ |
| aichat | ❌ | ❌ | ❌ | ✅ |
| llama.cpp | ❌ | ❌ | ❌ | ✅ |
| opencode-desktop | ❌ | ❌ | ❌ | ✅ |
| Ollama (serviço NixOS) | ❌ | ❌ | ❌ | opt |
| Open WebUI (Docker stack) | ❌ | ❌ | ❌ | opt |
| Tabby (self-hosted completion) | ❌ | ❌ | ❌ | opt |
| **Automação CI** | | | | |
| Woodpecker CI (Docker stack) | ❌ | opt | opt | opt |
| **Virtualização** | | | | |
| distrobox | ❌ | ❌ | ❌ | ✅ |
| QEMU / libvirtd | ❌ | ❌ | ❌ | opt |
| **SSH** | | | | |
| SSH key-only | ✅ | ✅ | ✅ | ✅ |

Legenda: ✅ incluído | ❌ não incluído | opt = opcional via toggle em `variables.nix`

¹ **Hermes Agent**: não disponível no nixpkgs. Consulte: https://github.com/NousResearch/hermes-agent

² **opencode-desktop**: GUI Desktop do OpenCode. Disponível no nixpkgs unstable (v1.15.7+).
Instalado na edição **full** via `modules/ai-tools/tier3.nix`.
O CLI `opencode` já está disponível na edição **medium** (tier2).

---

## Ferramentas de IA e OpenRouter

Consulte os guias detalhados:

- [`docs/ai-tools.md`](ai-tools.md) — ferramentas por edição, comandos e exemplos
- [`docs/ai-tools-openrouter.md`](ai-tools-openrouter.md) — configuração segura do OpenRouter

**Configuração rápida:**
```bash
mkdir -p ~/.config/ai-tools
cp ~/zaneyos/docs/examples/openrouter.env.example ~/.config/ai-tools/openrouter.env
# edite o arquivo e defina OPENROUTER_API_KEY
ai-env-check
```

---

## Configurar a edição

Em `hosts/<hostname>/variables.nix`:

```nix
{
  edition = "medium";  # "vm" | "basic" | "medium" | "full"
}
```

Após alterar, reconstruir o sistema:

```bash
zcli rebuild
```

---

## Módulos NixOS por edição

| Arquivo | Papel |
|---|---|
| `modules/editions/vm.nix` | Plymouth desabilitado, Docker desabilitado por padrão |
| `modules/editions/basic.nix` | Base dev + Caddy + DNS local + Docker |
| `modules/editions/medium.nix` | Importa basic + JVM + cloud + kubernetes |
| `modules/editions/full.nix` | Importa medium + k3d + Firebase + aichat + distrobox |

O módulo de edição é carregado automaticamente em `modules/core/default.nix`
com base no valor de `vars.edition`.

---

## Secrets e SOPS (edições Basic+)

As edições `basic`, `medium` e `full` habilitam automaticamente:

- **Secrets** gerenciados via `zstack init` (age encryption disponível via `zstack encrypt`)

**Setup inicial (após rebuild):**

```bash
# 1. Gerar senhas aleatórias
zstack secrets-init

# 2. Copiar configuração para variables.nix
zstack secrets-show

# 3. Rebuild para aplicar
zcli rebuild
```

Veja [`docs/secrets.md`](secrets.md) para o guia completo.

---

## Ativar Ollama (edição Full)

O serviço Ollama está comentado por padrão para não ocupar espaço com modelos.
Para ativar, edite `modules/editions/full.nix`:

```nix
# Descomente a linha abaixo:
services.ollama.enable = true;
```

Em seguida, baixe modelos manualmente:

```bash
ollama pull llama3
ollama pull codellama
```

> Os modelos ficam em `~/.ollama/models` e podem ocupar vários GB.
> Certifique-se de ter armazenamento suficiente (edição Full recomenda 500 GB+).
