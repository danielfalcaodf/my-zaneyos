# Woodpecker CI — Guia Completo

Woodpecker CI é uma plataforma de CI/CD open source, leve e auto-hospedada.
Integra-se com GitHub, Gitea e Forgejo.

---

## Subindo o stack

```bash
# 1. Inicializar .env (copia .env.example)
zstack init automation/woodpecker

# 2. Editar o .env com seus valores reais
nano docker/stacks/automation/woodpecker/.env

# 3. Subir o stack
zstack up automation/woodpecker

# 4. Ver logs
zstack logs automation/woodpecker
```

Acesse em: http://localhost:8000 (ou via Caddy no hostname configurado)

---

## 1. Criar OAuth App no GitHub

1. Acesse: https://github.com/settings/developers → **OAuth Apps** → **New OAuth App**

2. Preencha:

   | Campo | Valor |
   |-------|-------|
   | Application name | `Woodpecker CI (Homelab)` |
   | Homepage URL | valor de `WOODPECKER_HOST` |
   | Authorization callback URL | `${WOODPECKER_HOST}/authorize` |

   Exemplo com hostname local:
   ```
   Authorization callback URL: http://woodpecker.homelab.lan/authorize
   ```

3. Clique em **Register application**
4. Copie o **Client ID** e gere um **Client Secret**
5. Coloque em `.env`:
   ```bash
   WOODPECKER_GITHUB_CLIENT=<client-id>
   WOODPECKER_GITHUB_SECRET=<client-secret>
   ```

---

## 2. Gerar o WOODPECKER_AGENT_SECRET

```bash
openssl rand -hex 32
```

Cole o resultado em `.env`:
```bash
WOODPECKER_AGENT_SECRET=<resultado-do-openssl>
```

> ⚠️ O mesmo secret é usado pelo server e pelo agent.
> O compose já compartilha via variável de ambiente — não duplique.

---

## 3. Configurar WOODPECKER_HOST

```bash
# Via reverse proxy Caddy (recomendado para homelab)
WOODPECKER_HOST=http://woodpecker.homelab.lan

# Acesso direto por IP (sem reverse proxy)
WOODPECKER_HOST=http://192.168.0.10:8000
```

**Regras importantes:**
- Sem trailing slash
- Deve ser a URL exata usada para acessar o Woodpecker
- A callback URL do OAuth App deve ser `${WOODPECKER_HOST}/authorize`

---

## 4. Reverse proxy com Caddy

Se estiver usando o stack `homelab/caddy`, adicione ao `Caddyfile`:

```caddy
# Acesso HTTP local (sem TLS — para LAN apenas)
http://woodpecker.homelab.lan {
    reverse_proxy localhost:8000
}

# Ou com TLS interno (certificado auto-assinado via Caddy)
woodpecker.homelab.lan {
    reverse_proxy localhost:8000
    tls internal
}
```

Configure também no Blocky DNS:
```yaml
# Em modules/core/blocky.nix ou equivalente:
customDNS:
  mapping:
    woodpecker.homelab.lan: 127.0.0.1
```

---

## 5. Primeiro pipeline

Crie `.woodpecker.yml` na raiz do repositório a ser integrado:

```yaml
# .woodpecker.yml — Pipeline básico
steps:
  - name: hello
    image: alpine
    commands:
      - echo "✅ Pipeline Woodpecker rodando!"
      - echo "Branch: $CI_COMMIT_BRANCH"
      - echo "Commit: $CI_COMMIT_SHA"
```

Push para o GitHub → Woodpecker detecta via webhook → executa o pipeline.

### Pipeline para my-zaneyos

Para validar este repositório, use o exemplo em `.woodpecker/example.yml`
(não ativado por padrão — copie para `.woodpecker.yml` quando pronto):

```bash
cp .woodpecker/example.yml .woodpecker.yml
```

---

## 6. Volumes e persistência

| Volume Docker | Conteúdo | Importância |
|---------------|----------|-------------|
| `woodpecker-server-data` | Banco SQLite — usuários, repos, pipelines | 🔴 Crítico — faça backup |
| `woodpecker-agent-config` | Configuração do agent | 🟡 Reconstrói automaticamente |

### Backup do banco SQLite

```bash
# Localizar o volume
docker volume inspect woodpecker-server-data

# Fazer backup
docker run --rm \
  -v woodpecker-server-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/woodpecker-backup-$(date +%Y%m%d).tar.gz /data
```

---

## 7. Segurança — /var/run/docker.sock

O agent monta o socket Docker para executar pipelines como containers.

**Implicações:**
- O agent tem controle total sobre o daemon Docker do host
- Um pipeline malicioso pode comprometer o sistema inteiro
- Nunca exponha o agent publicamente

**Alternativas mais seguras para produção:**
- Docker-in-Docker (`dind`) — isolamento maior, mas mais complexo
- Rootless Docker — reduz superfície de ataque
- Agentes em VM separada

Para homelab local, o risco é aceitável com as seguintes práticas:
- Apenas seus repositórios privados ativados no Woodpecker
- `WOODPECKER_OPEN=false` para não permitir auto-cadastro público
- Porta `8000` apenas em `127.0.0.1` (não exposta na rede)

---

## 8. Integração com o workflow Discord + Claude Code

O Woodpecker CI completa o ciclo de automação:

```
Claude Code (local) → commit → push → GitHub
                                          ↓
                              Woodpecker CI executa
                                          ↓
                              Resultado: ✅ passou / ❌ falhou
                                          ↓
                         (futuro) Notificação Discord via webhook
```

Para notificações futuras no Discord:
```yaml
# .woodpecker.yml (futuro — quando webhook Discord configurado)
notify:
  - name: discord-notify
    image: appleboy/drone-discord
    settings:
      webhook_id:
        from_secret: DISCORD_WEBHOOK_ID
      webhook_token:
        from_secret: DISCORD_WEBHOOK_TOKEN
    when:
      status: [failure]
```

---

## 9. Alternativas — Gitea / Forgejo

Para usar Gitea ou Forgejo como forge (em vez de GitHub):

```bash
# No .env, substitua as variáveis GitHub:
WOODPECKER_GITHUB=false
WOODPECKER_GITEA=true
WOODPECKER_GITEA_URL=http://gitea.homelab.lan

# OAuth App no Gitea:
# Settings → Applications → Manage OAuth2 Applications
# Callback URL: ${WOODPECKER_HOST}/authorize
```

---

## Referências

- Documentação oficial: https://woodpecker-ci.org/docs/administration/installation/docker-compose
- Configuração do server: https://woodpecker-ci.org/docs/administration/configuration/server
- Plugins disponíveis: https://woodpecker-ci.org/plugins
- Variáveis de ambiente CI: https://woodpecker-ci.org/docs/usage/environment
