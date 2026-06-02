# Instruções para o Agente de IA — my-zaneyos

Este arquivo define as regras de trabalho para agentes de IA (Claude Code, etc.)
neste repositório.

---

## Identidade do projeto

- **Repositório**: `my-zaneyos` — fork customizado do ZaneyOS (NixOS flake + Home Manager)
- **Branch principal de trabalho**: `feat/devdaniel-homelab-editions`
- **Linguagem principal**: Nix (NixOS/Home Manager), Bash, YAML
- **Objetivo**: Homelab pessoal com edições vm/basic/medium/full

---

## Regras obrigatórias

### Antes de implementar qualquer coisa
1. **Analise a estrutura atual** — leia os arquivos relevantes primeiro
2. **Escreva um plano** — explique o que vai fazer antes de fazer
3. **Aguarde aprovação** — não implemente sem confirmação explícita

### Durante a implementação
4. **Faça alterações pequenas** — um arquivo ou funcionalidade por vez
5. **Nunca use `git add .`** — sempre adicione arquivos específicos
6. **Sempre mostre o `git diff`** antes de propor um commit
7. **Commits no formato Conventional Commits** — `feat:`, `fix:`, `docs:`, `chore:`
8. **Não faça `git push`** sem confirmação explícita do usuário

### Arquivos protegidos — nunca modifique
- `.env` (qualquer arquivo .env)
- `secrets/`, `.ssh/`, `*.key`, `*.pem`
- `hardware.nix` de hosts reais
- Qualquer arquivo com token, senha ou chave

### Pacotes Nix
- **Nunca invente nomes de pacotes** — verifique em https://search.nixos.org
- Se o pacote não existir, documente como TODO com link de referência
- Siga o padrão de tiers: `modules/ai-tools/tier{1,2,3}.nix`

---

## Estrutura do repositório

```
flake.nix                          ← entrada do flake
hosts/<hostname>/variables.nix    ← configuração por host (único arquivo que o usuário edita)
modules/editions/{vm,basic,medium,full}.nix  ← camadas de features
modules/ai-tools/{tier1,tier2,tier3}.nix     ← ferramentas de IA por edição
modules/home/scripts/             ← scripts Nix (pkgs.writeShellScriptBin)
docker/stacks/<cat>/<stack>/      ← stacks Docker (compose.yml + .env.example + README.md)
docs/                             ← documentação
scripts/ai/                       ← scripts shell de automação de agente
```

---

## Comandos permitidos para validação

```bash
# Verificar se o flake compila (sem aplicar)
nix flake check --no-build

# Rebuild seguro (preview)
zcli rebuild --dry

# Verificar scripts
shellcheck scripts/ai/*

# Status do git
git status
git diff HEAD
git log --oneline -10

# Listar stacks Docker
zstack list
zstack doctor
```

---

## Fluxo de commit aprovado

```bash
# 1. Ver o que mudou
git diff HEAD

# 2. Adicionar apenas o que é necessário
git add modules/home/scripts/zstack.nix
git add modules/home/scripts/default.nix

# 3. Commit descritivo
git commit -m "feat(scripts): add zstack script for docker stack management"

# NÃO fazer push automaticamente — aguardar confirmação do usuário
```

---

## Regras de segurança para automação

- Nunca executar `rm -rf` ou comandos irreversíveis
- Nunca usar `sudo` em scripts de automação
- Nunca modificar `.env` existente (apenas `.env.example`)
- Nunca commitar secrets — rodar `git diff --staged` antes do commit
- Nunca fazer `git push --force`
- Sempre usar branch de trabalho, não `main`

---

## Estilo de código

### Nix
- Formatar com `nix fmt` (alejandra) antes de commitar
- Comentar pacotes com uso/propósito
- Não hardcodar valores específicos de host — usar `vars.atributo`

### Bash (scripts Nix)
- `#!/usr/bin/env bash` + `set -euo pipefail`
- Mensagens de erro para stderr: `echo "..." >&2`
- Funções auxiliares para info/ok/warn/err com cores
- Validar argumentos antes de executar

### Docker Compose
- Portas apenas em `127.0.0.1:HOST:CONTAINER`
- Secrets apenas via variáveis de ambiente do `.env`
- Sempre criar `.env.example` e `README.md`
- Nunca expor portas em `0.0.0.0`

---

## Quando encontrar um problema

1. Explique o problema claramente
2. Proponha **uma** solução específica
3. Liste os riscos
4. Aguarde aprovação antes de implementar
5. Se houver múltiplas opções, apresente as 2-3 melhores com prós/contras
