# Workflow estilo Akita: IA como Par de Desenvolvimento

Metodologia de trabalho com IA inspirada no fluxo do Fabio Akita —
commits frequentes, revisão humana, CI contínuo, Discord como interface.

Referências:
- https://www.akitaonrails.com/en/2026/02/20/zero-to-post-production-in-1-week-using-ai-on-real-projects-behind-the-m-akita-chronicles/
- https://www.akitaonrails.com/en/2026/02/16/vibe-code-zero-to-production-in-6-days-the-m-akita-chronicles/

---

## O princípio fundamental

> **Não é automação cega. É pair programming com IA.**

A IA propõe, planeja e implementa.
**Você revisa, aprova e faz o commit.**

O Discord é o terminal remoto — não o executor automático.

---

## Fluxo recomendado

```
1. Escrever spec pequena
        │
        ▼
2. Pedir plano ao agente
        │
        ▼
3. Revisar e aprovar o plano
        │
        ▼
4. Agente implementa (com confirmação)
        │
        ▼
5. Rodar testes
   nix flake check / zcli rebuild --dry
        │
        ▼
6. Revisar git diff
   git diff HEAD
        │
        ▼
7. Commit pequeno e descritivo
   scripts/ai/agent-commit
        │
        ▼
8. Push → Woodpecker CI roda
        │
        ▼
9. Repetir para a próxima feature
```

---

## Por que commits pequenos?

- Cada commit representa uma intenção clara
- Fácil de reverter (`git revert`) se algo der errado
- CI valida cada mudança isoladamente
- Histórico legível (`git log --oneline`)
- Code review focado

**Regra prática:** se o commit message precisa de mais de uma linha de descrição, provavelmente deve ser dividido.

---

## Integração com Woodpecker CI

Após configurar o stack `automation/woodpecker`:

```
Push local
    │
    ▼
GitHub (fork danielfalcaodf/my-zaneyos)
    │  webhook
    ▼
Woodpecker CI
    │
    ├── nix flake check
    ├── shellcheck nos scripts
    ├── docker compose config (stacks principais)
    └── (futuro) notificação Discord via webhook
```

Para futuramente notificar o Discord sobre falhas/sucessos do CI,
configure um webhook no pipeline do Woodpecker:
```yaml
# .woodpecker.yml (futuro)
notify:
  - name: discord-notify
    image: appleboy/drone-discord
    settings:
      webhook_id: ${DISCORD_WEBHOOK_ID}
      webhook_token: ${DISCORD_WEBHOOK_TOKEN}
    when:
      status: [failure, success]
```

---

## Usando zellij para sessão persistente

Com `zellij` (disponível em medium+), mantenha o agente rodando:

```bash
# Iniciar sessão persistente
scripts/ai/claude-discord-session --project my-zaneyos

# Reconectar após fechar o terminal
zellij attach claude-my-zaneyos
```

O agente continua ativo mesmo se você fechar o terminal.

---

## Política de segurança explícita

### ✅ Permitido ao agente
- Ler qualquer arquivo do repositório
- Criar e editar arquivos de código
- Rodar `nix flake check`, `zcli rebuild --dry`
- Rodar `git status`, `git diff`, `git log`
- Criar commits com `git add <arquivo-específico>` + `git commit`
- Criar branches de trabalho

### ❌ Nunca permitido ao agente
- `git push` sem confirmação explícita do usuário
- `git add .` (sempre adicionar arquivos específicos)
- Modificar `.env` ou qualquer arquivo com secrets
- Executar `sudo` ou comandos com privilégios elevados
- `rm -rf` ou comandos destrutivos irreversíveis
- Modificar `.ssh/`, `secrets/`, ou diretórios protegidos
- Commitar chaves, tokens ou senhas

### 🔒 Proteção de arquivos sensíveis
Defina em `docs/examples/agent-projects.yaml`:
```yaml
protected_paths:
  - .env
  - secrets/
  - id_rsa
  - .ssh/
  - "*.key"
  - "*.pem"
```

---

## Formato de commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(módulo): descrição curta do que foi adicionado
fix(script): descrição do que foi corrigido
docs(automation): adiciona guia de workflow Discord
chore(deps): atualiza flake inputs
refactor(editions): simplifica importação de módulos
test(scripts): adiciona shellcheck ao CI
```

**Sem trailers automáticos.** Commits são humanos.

---

## TDD com IA

Para scripts shell:
1. Escrever teste com `shellcheck` / `bats`
2. Agente implementa o script para passar nos testes
3. `shellcheck scripts/ai/*` antes do commit

Para módulos Nix:
1. Descrever comportamento esperado
2. Agente implementa o módulo
3. `nix flake check` antes do commit
4. `zcli rebuild --dry` para validar sem aplicar

---

## Checklist antes de cada push

```bash
# 1. Verificar status
git status

# 2. Revisar diff completo
git diff HEAD

# 3. Rodar validações
nix flake check --no-build 2>/dev/null || echo "nix check falhou"
shellcheck scripts/ai/* 2>/dev/null || true

# 4. Commit descritivo
scripts/ai/agent-commit

# 5. Push para branch de trabalho
git push origin feat/devdaniel-homelab-editions
```

---

## Anti-padrões a evitar

| Anti-padrão | Alternativa |
|-------------|-------------|
| `git add .` | `git add <arquivo-específico>` |
| Commit gigante com 20 arquivos | Série de commits pequenos |
| Push sem CI | Aguardar Woodpecker validar |
| Agente com permissão total | `allowed_commands` restrito |
| Discord em servidor público | Servidor Discord privado |
| Token do bot no código | `~/.config/ai-tools/discord.env` |
