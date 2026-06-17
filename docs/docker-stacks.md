# Referência de Docker Stacks

Todos os stacks ficam em `docker/stacks/`. Cada um segue as mesmas convenções:
- Portas apenas em `127.0.0.1:HOST:CONTAINER`
- Segredos via `.env` (copiar do `.env.example`)
- Redes Docker internas para isolamento

---

## Estrutura de diretórios

Cada categoria segue o mesmo padrão do `homelab/`:

```
docker/stacks/
  homelab/
    compose.yml              ← ROOT: sobe caddy + portainer + homepage juntos
    caddy/compose.yml        ← standalone: apenas o caddy
    portainer/compose.yml    ← standalone: apenas o portainer
    homepage/compose.yml     ← standalone: apenas o homepage
  automation/
    compose.yml              ← ROOT: sobe todos os serviços de automação
    mailpit/compose.yml      ← standalone
    n8n/compose.yml          ← standalone
    uptime-kuma/compose.yml  ← standalone
    woodpecker/compose.yml   ← standalone
  databases/
    compose.yml              ← ROOT: sobe todos os bancos
    postgres/   mysql/   redis/   sqlserver/   adminer/   cloudbeaver/
  monitoring/
    compose.yml              ← ROOT: sobe grafana + loki + prometheus
    grafana/   loki/   prometheus/
  storage/
    compose.yml              ← ROOT: minio
    minio/
  llm/
    compose.yml              ← ROOT: open-webui
    open-webui/
```

**Root compose** → sobe tudo da categoria de uma vez: `zstack up automation`
**Standalone** → sobe apenas um serviço: `zstack up automation/n8n`

---

## Usando o script `zstack` (recomendado)

O `zstack` é o gerenciador de stacks integrado ao ZaneyOS (disponível após `zcli rebuild`):

```bash
# Listar todas as stacks (mostra root composes com [ROOT])
zstack list

# Listar apenas uma categoria
zstack list --category automation

# Inicializar .env a partir de .env.example (sem sobrescrever existentes)
zstack init                         # todas as categorias
zstack init automation              # apenas serviços de automation/
zstack init automation/woodpecker   # apenas woodpecker

# Subir uma categoria inteira (root compose)
zstack up automation
zstack up databases
zstack up monitoring

# Subir apenas um serviço (standalone)
zstack up homelab/homepage
zstack up automation/n8n

# Outros comandos (funcionam para root e standalone)
zstack down automation
zstack restart homelab/homepage
zstack logs automation/n8n

# Ver status de todos os containers
zstack ps

# Diagnosticar problemas
zstack doctor

# Atualizar imagens e recriar
zstack update llm

# Ver volumes que precisam backup
zstack backup-info
```

---

## Como usar manualmente (alternativa)

```bash
# Subir o root compose de uma categoria
cd ~/zaneyos/docker/stacks/automation
docker compose up -d

# Subir apenas um serviço
cd ~/zaneyos/docker/stacks/automation/n8n
cp .env.example .env
# Edite o .env com suas senhas reais
docker compose up -d

# Logs
docker compose logs -f

# Parar
docker compose down

# Parar e remover dados (irreversível)
docker compose down -v
```

---

## Homelab

### Portainer
**Diretório:** `homelab/portainer/` | **Porta:** `9000` | **URL:** http://portainer.localhost

```bash
# Primeiro acesso: criar usuário admin em http://localhost:9000
```

Gerenciador visual de containers Docker. Permite criar, monitorar e remover containers via interface web.

---

### Caddy (Docker standalone)
**Diretório:** `homelab/caddy/` | **Porta:** `80`

```bash
cp Caddyfile.example Caddyfile
# Edite o Caddyfile conforme seus serviços
docker compose up -d
```

> Use apenas se não estiver usando o módulo NixOS `caddy.nix`.

---

### Homepage
**Diretório:** `homelab/homepage/` | **Porta:** `3003` | **URL:** http://home.homelab.lan

```bash
zstack init homelab/homepage
# Edite o .env com seus hosts permitidos:
nano docker/stacks/homelab/homepage/.env
# Configure serviços (copie o exemplo e personalize):
cp docker/stacks/homelab/homepage/config/services.yaml.example docker/stacks/homelab/homepage/config/services.yaml
nano docker/stacks/homelab/homepage/config/services.yaml
zstack up homelab/homepage
```

Dashboard configurável para homelab. Personalize serviços em `config/services.yaml` (use `services.yaml.example` como base).
Veja também: `config/bookmarks.yaml`, `config/widgets.yaml`, `config/settings.yaml`.

> **Erro "Host validation failed"?** Veja a seção de troubleshooting abaixo.

#### HOMEPAGE_ALLOWED_HOSTS

O Homepage exige que os hosts usados para acessá-lo estejam na lista `HOMEPAGE_ALLOWED_HOSTS`.

Configure no `.env`:
```bash
# Via hostname local (Caddy + DNS):
HOMEPAGE_ALLOWED_HOSTS=homepage.homelab.lan,home.homelab.lan,localhost:3003,127.0.0.1:3003

# Via IP da LAN:
HOMEPAGE_ALLOWED_HOSTS=192.168.0.10:3003,localhost:3003
```

**Troubleshooting — Host validation failed:**
```bash
# 1. Ver o host exato no log:
zstack logs homelab/homepage

# 2. Copie o host que aparece no erro (ex: "192.168.0.10:3003")
# 3. Adicione ao .env e recriar o container (restart simples não aplica envs):
zstack restart homelab/homepage
# ou:
cd docker/stacks/homelab/homepage
docker compose up -d --force-recreate
```

> ⚠️ `HOMEPAGE_ALLOWED_HOSTS=*` desabilita a validação e **não é recomendado**.
> Use apenas para debug temporário.

---

## Bancos de dados

> ⚠️ Todos os bancos ficam em `127.0.0.1` — nunca expostos na rede.
>
> As senhas são gerenciadas via **sops-nix** e os `.env` files são criados
> automaticamente no rebuild. Veja [`docs/secrets.md`](secrets.md) para o guia
> completo de configuração.

### PostgreSQL
**Diretório:** `databases/postgres/` | **Porta:** `5432` | **Edição:** basic+

```bash
# O .env é gerado automaticamente pelo sops-nix (após zstack secrets-init + rebuild)
zstack up databases/postgres
# Conectar: psql -h 127.0.0.1 -U postgres
```

> Senha definida em `secrets.yaml` → gerada via `zstack secrets-init` → `.env` criado automaticamente.
> Veja [`docs/secrets.md`](secrets.md).

---

### MySQL
**Diretório:** `databases/mysql/` | **Porta:** `3306` | **Edição:** medium+

```bash
zstack up databases/mysql
# Conectar: mysql -h 127.0.0.1 -u root -p
```

---

### SQL Server
**Diretório:** `databases/sqlserver/` | **Porta:** `1433` | **Edição:** medium+

```bash
zstack up databases/sqlserver
```

---

### Redis
**Diretório:** `databases/redis/` | **Porta:** `6379` | **Edição:** medium+

```bash
zstack up databases/redis
# Conectar: redis-cli -h 127.0.0.1
```

---

### Adminer (gerenciador de bancos — web)
**Diretório:** `databases/adminer/` | **Porta:** `8082` | **URL:** http://db.localhost | **Edição:** basic+

Interface web para acessar PostgreSQL, MySQL, SQLite e outros.

---

### CloudBeaver (gerenciador enterprise — web)
**Diretório:** `databases/cloudbeaver/` | **Porta:** `8978` | **URL:** http://cloudbeaver.localhost | **Edição:** medium+

---

## Monitoring

> Os stacks de monitoring compartilham a rede Docker `monitoring`.
> Suba o Grafana primeiro para criar a rede, depois Prometheus/Loki.

### Grafana
**Diretório:** `monitoring/grafana/` | **Porta:** `3000` | **URL:** http://grafana.localhost | **Edição:** medium+

```bash
cp .env.example .env  # Defina GF_ADMIN_PASSWORD
docker compose up -d
# Login padrão: admin / (valor do .env)
```

---

### Prometheus
**Diretório:** `monitoring/prometheus/` | **Porta:** `9090` | **Edição:** medium+

```bash
cp prometheus.yml.example prometheus.yml
# Edite prometheus.yml para adicionar scrape targets
docker compose up -d
```

> A rede `monitoring` deve existir antes (criada pelo Grafana). Execute Grafana primeiro.

---

### Loki
**Diretório:** `monitoring/loki/` | **Porta:** `3100` | **Edição:** full (opcional)

```bash
docker compose up -d
```

Configure Loki como datasource no Grafana: `http://loki:3100`

---

## Automação

### n8n
**Diretório:** `automation/n8n/` | **Porta:** `5678` | **URL:** http://n8n.localhost | **Edição:** medium+

```bash
cp .env.example .env
# OBRIGATÓRIO: defina N8N_ENCRYPTION_KEY (string aleatória)
openssl rand -hex 32  # use este valor para N8N_ENCRYPTION_KEY
docker compose up -d
```

O stack inclui PostgreSQL dedicado para o n8n. Aguarde o healthcheck do banco antes de acessar.

---

### Uptime Kuma
**Diretório:** `automation/uptime-kuma/` | **Porta:** `3001` | **URL:** http://uptime.localhost | **Edição:** medium+

```bash
docker compose up -d
# Primeiro acesso: criar usuário admin
```

Monitor de uptime para serviços locais e externos.

---

### Mailpit
**Diretório:** `automation/mailpit/` | **Portas:** `8025` (UI) / `1025` (SMTP) | **URL:** http://mail.localhost | **Edição:** medium+

```bash
docker compose up -d
```

Servidor SMTP local para desenvolvimento. Configure suas aplicações para usar:
- Host: `127.0.0.1`
- Porta SMTP: `1025`
- Sem autenticação (ou qualquer usuário/senha)

---

### Woodpecker CI
**Diretório:** `automation/woodpecker/` | **Porta:** `8000` | **Edição:** opt (qualquer)

Plataforma de CI/CD open source. Integra-se com GitHub e Gitea.

```bash
zstack init automation/woodpecker
# Edite o .env: WOODPECKER_HOST, GITHUB OAuth, AGENT_SECRET
nano docker/stacks/automation/woodpecker/.env
zstack up automation/woodpecker
```

Veja o guia completo em: [`docs/woodpecker-ci.md`](woodpecker-ci.md)

---

## Storage

### MinIO
**Diretório:** `storage/minio/` | **Portas:** `9001` (API S3) / `9002` (console) | **URL:** http://minio.localhost | **Edição:** medium+

```bash
cp .env.example .env  # Defina MINIO_ROOT_PASSWORD
docker compose up -d
```

Object storage compatível com S3. Configure clientes com endpoint `http://127.0.0.1:9001`.

---

## LLM / IA

### Open WebUI
**Diretório:** `llm/open-webui/` | **Porta:** `8080` | **Edição:** full

```bash
cp .env.example .env
# OLLAMA_BASE_URL: mantenha http://host-gateway:11434 se Ollama está no host
docker compose up -d
```

> Requer Ollama rodando no host. Para ativar Ollama, edite `modules/editions/full.nix`
> e descomente `services.ollama.enable = true;`, depois rebuild.

---

## Referência de portas

| Serviço | Porta | URL local (https) | URL Docker standalone (http) |
|---|---|---|---|
| Homepage | 3003 | https://home.homelab.lan | http://home.localhost |
| Portainer | 9000 | https://portainer.homelab.lan | http://portainer.localhost |
| Caddy | 80/443 | — | — |
| PostgreSQL | 5432 | — | — |
| MySQL | 3306 | — | — |
| SQL Server | 1433 | — | — |
| Redis | 6379 | — | — |
| Adminer | 8082 | https://db.homelab.lan | http://db.localhost |
| CloudBeaver | 8978 | https://cloudbeaver.homelab.lan | http://cloudbeaver.localhost |
| Grafana | 3000 | https://grafana.homelab.lan | http://grafana.localhost |
| Prometheus | 9090 | https://prometheus.homelab.lan | http://prometheus.localhost |
| Loki | 3100 | — | — |
| n8n | 5678 | https://n8n.homelab.lan | http://n8n.localhost |
| Uptime Kuma | 3001 | https://uptime.homelab.lan | http://uptime.localhost |
| Mailpit UI | 8025 | https://mail.homelab.lan | http://mail.localhost |
| Mailpit SMTP | 1025 | — | — |
| Woodpecker CI | 8000 | https://woodpecker.homelab.lan | http://woodpecker.localhost |
| MinIO API | 9001 | https://minio.homelab.lan | http://minio.localhost |
| MinIO Console | 9002 | — | — |
| Open WebUI | 8080 | https://openwebui.homelab.lan | http://openwebui.localhost |
