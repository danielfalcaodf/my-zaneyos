# Referência de Docker Stacks

Todos os stacks ficam em `docker/stacks/`. Cada um segue as mesmas convenções:
- Portas apenas em `127.0.0.1:HOST:CONTAINER`
- Segredos via `.env` (copiar do `.env.example`)
- Redes Docker internas para isolamento

---

## Como usar qualquer stack

```bash
cd ~/zaneyos/docker/stacks/<categoria>/<stack>
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
**Diretório:** `homelab/homepage/` | **Porta:** `3003` | **URL:** http://home.localhost

```bash
cp config/settings.yaml.example config/settings.yaml
docker compose up -d
```

Dashboard configurável para homelab. Adicione serviços em `config/services.yaml`.

---

## Bancos de dados

> ⚠️ Todos os bancos ficam em `127.0.0.1` — nunca expostos na rede.

### PostgreSQL
**Diretório:** `databases/postgres/` | **Porta:** `5432` | **Edição:** basic+

```bash
cp .env.example .env  # Defina POSTGRES_PASSWORD
docker compose up -d
# Conectar: psql -h 127.0.0.1 -U postgres
```

---

### MySQL
**Diretório:** `databases/mysql/` | **Porta:** `3306` | **Edição:** medium+

```bash
cp .env.example .env  # Defina MYSQL_ROOT_PASSWORD
docker compose up -d
# Conectar: mysql -h 127.0.0.1 -u root -p
```

---

### SQL Server
**Diretório:** `databases/sqlserver/` | **Porta:** `1433` | **Edição:** medium+

```bash
cp .env.example .env  # Defina SA_PASSWORD (mín. 8 chars, 1 maiúscula, 1 número, 1 especial)
docker compose up -d
```

---

### Redis
**Diretório:** `databases/redis/` | **Porta:** `6379` | **Edição:** medium+

```bash
docker compose up -d
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

| Serviço | Porta | URL local |
|---|---|---|
| Portainer | 9000 | http://portainer.localhost |
| Caddy | 80 | — |
| Homepage | 3003 | http://home.localhost |
| PostgreSQL | 5432 | — |
| MySQL | 3306 | — |
| SQL Server | 1433 | — |
| Redis | 6379 | — |
| Adminer | 8082 | http://db.localhost |
| CloudBeaver | 8978 | http://cloudbeaver.localhost |
| Grafana | 3000 | http://grafana.localhost |
| Prometheus | 9090 | — |
| Loki | 3100 | — |
| n8n | 5678 | http://n8n.localhost |
| Uptime Kuma | 3001 | http://uptime.localhost |
| Mailpit UI | 8025 | http://mail.localhost |
| Mailpit SMTP | 1025 | — |
| MinIO API | 9001 | http://minio.localhost |
| MinIO Console | 9002 | — |
| Open WebUI | 8080 | — |
