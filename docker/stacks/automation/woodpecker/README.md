# Woodpecker CI — Stack Docker

Woodpecker CI é uma plataforma de CI/CD leve e open source, compatível com GitHub, Gitea e Forgejo.

- **Server**: interface web + API (porta 8000)
- **Agent**: executa os pipelines como containers Docker

---

## Pré-requisitos

- Docker e Docker Compose instalados
- `zstack` disponível (instalado com `zcli rebuild`)
- Acesso ao GitHub para criar o OAuth App
- Caddy ou outro reverse proxy para acesso via hostname (opcional)

---

## 1. Criar OAuth App no GitHub

1. Acesse: https://github.com/settings/developers → **OAuth Apps** → **New OAuth App**
2. Preencha:
   - **Application name**: `Woodpecker CI (Homelab)`
   - **Homepage URL**: valor de `WOODPECKER_HOST` (ex: `http://woodpecker.homelab.lan`)
   - **Authorization callback URL**: `${WOODPECKER_HOST}/authorize`
     - Exemplo: `http://woodpecker.homelab.lan/authorize`
3. Clique em **Register application**
4. Copie o **Client ID** e gere um **Client Secret**

---

## 2. Configurar o .env

```bash
zstack init automation/woodpecker
# Agora edite o .env:
nano docker/stacks/automation/woodpecker/.env
```

Campos obrigatórios:
```bash
WOODPECKER_HOST=http://woodpecker.homelab.lan   # sem trailing slash
WOODPECKER_GITHUB_CLIENT=<client-id-do-github>
WOODPECKER_GITHUB_SECRET=<client-secret-do-github>
WOODPECKER_AGENT_SECRET=<gere-abaixo>
```

### Gerar o WOODPECKER_AGENT_SECRET

```bash
openssl rand -hex 32
```

Copie o resultado para `WOODPECKER_AGENT_SECRET` no `.env`.  
> ⚠️ **O mesmo secret deve estar em `WOODPECKER_AGENT_SECRET` no server e no agent.**  
> O compose já faz isso automaticamente — não duplique manualmente.

---

## 3. Subir o stack

```bash
zstack up automation/woodpecker
```

Ou manualmente:
```bash
cd docker/stacks/automation/woodpecker
docker compose up -d
```

---

## 4. Acessar e configurar

- **URL local**: http://localhost:8000 (ou `WOODPECKER_SERVER_PORT`)
- **URL via reverse proxy**: valor de `WOODPECKER_HOST`

No primeiro acesso, faça login com sua conta GitHub.  
Se `WOODPECKER_ADMIN=daniel` estiver configurado, o usuário `daniel` será admin automaticamente.

---

## 5. Ver logs

```bash
zstack logs automation/woodpecker
```

Ou separadamente:
```bash
cd docker/stacks/automation/woodpecker
docker compose logs -f woodpecker-server
docker compose logs -f woodpecker-agent
```

---

## 6. Reverse proxy com Caddy

Se estiver usando o stack `homelab/caddy`, adicione ao `Caddyfile`:

```caddy
woodpecker.homelab.lan {
    reverse_proxy localhost:8000
    tls internal
}
```

Ou para acesso local sem TLS:
```caddy
http://woodpecker.homelab.lan {
    reverse_proxy localhost:8000
}
```

> `WOODPECKER_HOST` deve ser exatamente a URL definida no Caddyfile (sem trailing slash).

---

## 7. Primeiro pipeline

Crie um arquivo `.woodpecker.yml` na raiz do repositório que deseja integrar:

```yaml
steps:
  - name: hello
    image: alpine
    commands:
      - echo "Pipeline rodando no Woodpecker CI!"
```

Push para o GitHub → Woodpecker detecta e roda o pipeline automaticamente.

---

## Volumes e persistência

| Volume | Conteúdo |
|--------|----------|
| `woodpecker-server-data` | Banco SQLite com usuários, repos e pipelines |
| `woodpecker-agent-config` | Configuração do agent |

> **Faça backup do volume `woodpecker-server-data`.**  
> Use `docker volume inspect woodpecker-server-data` para localizar no host.

---

## ⚠️ Segurança — /var/run/docker.sock

O agent monta `/var/run/docker.sock` para executar pipelines como containers Docker.

Isso concede ao agent **controle total sobre o daemon Docker do host**.

Boas práticas:
- Nunca exponha o agent publicamente (porta bloqueada no host)
- Use apenas em homelab controlado
- Considere Docker-in-Docker (`dind`) como alternativa mais isolada em produção
- Mantenha o agent atualizado com a versão do server

---

## Alternativas futuras

- **Gitea/Forgejo**: substitua `WOODPECKER_GITHUB=true` por `WOODPECKER_GITEA=true` e configure `WOODPECKER_GITEA_URL`
- **Múltiplos agents**: replique o serviço `woodpecker-agent` com nomes diferentes
- **Notificações Discord**: configure webhook no pipeline após criar o bot

---

## Referências

- Documentação oficial: https://woodpecker-ci.org/docs/administration/installation/docker-compose
- Configuração do server: https://woodpecker-ci.org/docs/administration/configuration/server
- Plugins/extensões: https://woodpecker-ci.org/plugins
