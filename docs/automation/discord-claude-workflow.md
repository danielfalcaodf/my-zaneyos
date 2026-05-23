# Workflow Discord + Claude Code Channels

Guia para controlar sessões de Claude Code via Discord de forma segura,
usando Claude Code Channels (interface experimental da Anthropic).

---

## Visão geral do fluxo

```
Você no Discord
     │
     │ (mensagem no canal)
     ▼
Claude Code Channels (plugin Discord)
     │
     │ (evento de canal)
     ▼
Sessão Claude Code local (no seu terminal/zellij)
     │
     │ (lê o projeto, faz alterações, cria commits)
     ▼
Repositório Git local → push manual → Woodpecker CI
```

**O agente roda localmente.** O Discord é apenas a interface de entrada.
Nenhum comando é executado automaticamente sem revisão.

---

## Pré-requisitos

- Claude Code instalado (`claude --version`)
  - Edição basic+ já instala via `modules/ai-tools/tier1.nix`
- Conta Claude.ai com acesso ao Claude Code
- Discord com servidor próprio (não usar servidor de terceiros)
- `zellij` disponível (edição medium+) para sessão persistente

---

## 1. Criar Discord App / Bot

1. Acesse: https://discord.com/developers/applications
2. Clique em **New Application** → dê um nome (ex: `Claude Homelab`)
3. Vá em **Bot** → clique em **Add Bot**
4. Em **Privileged Gateway Intents**, habilite:
   - ✅ **Message Content Intent** (obrigatório para ler mensagens)
5. Em **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Bot Permissions: `Send Messages`, `Read Message History`, `View Channels`
6. Copie a URL gerada e abra no navegador para convidar o bot ao seu servidor
7. Em **Bot → Token**, clique em **Reset Token** e copie o token

> ⚠️ **Segurança do token:**
> - Nunca coloque o token em arquivos commitados
> - Armazene apenas em `~/.config/ai-tools/discord.env` (fora do repo)
> - Nunca compartilhe o token

---

## 2. Instalar o plugin Discord no Claude Code

```bash
# Dentro de uma sessão claude:
/plugin install discord@claude-plugins-official
/reload-plugins

# Configurar o token do bot:
/discord:configure <seu-discord-bot-token>
```

Referência oficial: https://github.com/anthropics/claude-plugins-official/blob/main/external_plugins/discord/README.md

---

## 3. Iniciar sessão com Claude Code Channels

```bash
# Usando o script auxiliar (recomendado):
scripts/ai/claude-discord-session

# Ou manualmente:
cd ~/repos/my-zaneyos
claude --channels plugin:discord@claude-plugins-official
```

Com `zellij` (edição medium+), use o script para criar uma sessão persistente:
```bash
scripts/ai/claude-discord-session --project my-zaneyos
```

---

## 4. Parear usuário e canal Discord

Após iniciar a sessão com o plugin Discord ativo:
1. No Discord, vá ao canal onde o bot está
2. Envie: `@Claude homelab` (ou o nome do bot)
3. Siga as instruções de pareamento da sessão

Consulte a documentação oficial do plugin para o fluxo exato:
https://github.com/anthropics/claude-plugins-official/blob/main/external_plugins/discord/README.md

> **Nota:** Claude Code Channels pode ser um Research Preview.
> Verifique disponibilidade: https://code.claude.com/docs/en/channels

---

## 5. Usar com o repositório

Depois de pareado, envie tarefas no Discord:

```
Analise o arquivo modules/editions/medium.nix e me diga quais pacotes estão instalados
```

```
Crie um TODO em docs/ sobre adicionar suporte a Gitea no Woodpecker CI
```

O agente **lê** e **planeja** antes de agir. Não faz commits automaticamente.

---

## Política de segurança

- ❌ Nunca executar `rm -rf`, `sudo`, `git push --force` via Discord
- ❌ Nunca ler ou modificar `.env`, `secrets/`, `.ssh/`
- ❌ Nunca fazer push automático sem revisão humana
- ❌ Nunca commitar `.env` ou chaves privadas
- ✅ Sempre revisar o `git diff` antes de qualquer commit
- ✅ Sempre rodar testes/CI antes de push
- ✅ Commits pequenos e descritivos (Conventional Commits)
- ✅ Usar branch de trabalho, não `main` diretamente

---

## Riscos e limitações

| Risco | Mitigação |
|-------|-----------|
| Token do bot vazado | Armazenar em `~/.config/ai-tools/discord.env`, nunca no repo |
| Comando destrutivo via chat | Plugin não executa comandos shell diretamente |
| Sessão pública | Use servidor Discord privado, bot convidado apenas lá |
| Claude Code Channels como Preview | Verifique docs oficiais — pode ter mudanças |
| Acesso a arquivos sensíveis | `protected_paths` em `agent-projects.yaml` |

---

## Referências

- Claude Code Channels: https://code.claude.com/docs/en/channels
- Plugin Discord: https://github.com/anthropics/claude-plugins-official/blob/main/external_plugins/discord/README.md
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code
