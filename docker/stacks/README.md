# Docker Stacks — ZaneyOS Custom Homelab

Stacks Docker composáveis para homelab, bancos, monitoring e LLM.

## Regras de segurança
- **Todos os bancos** ficam em `127.0.0.1:PORT:PORT` (nunca `0.0.0.0`)
- **Caddy** faz reverse proxy para acessar serviços externamente
- **Secrets**: copie `.env.example` → `.env` e preencha. O `.env` está no `.gitignore`
- **Nunca** commite arquivos `.env` com senhas reais

## Como usar

```bash
# Copiar e configurar variáveis
cp .env.example .env
nano .env

# Subir um stack
cd databases/postgres
docker compose up -d

# Ver logs
docker compose logs -f

# Derrubar
docker compose down
```

## Stacks disponíveis

### Homelab
| Stack | Porta local | Descrição |
|---|---|---|
| `homelab/portainer` | 9000 | Gerenciador Docker visual |
| `homelab/caddy` | 80 | Reverse proxy (standalone Docker) |
| `homelab/homepage` | 3003 | Dashboard de homelab |

### Bancos de dados
| Stack | Porta local | Edição |
|---|---|---|
| `databases/postgres` | 5432 | Basic+ |
| `databases/mysql` | 3306 | Basic+ |
| `databases/sqlserver` | 1433 | Medium+ |
| `databases/redis` | 6379 | Basic+ |
| `databases/adminer` | 8082 | Basic/VM |
| `databases/cloudbeaver` | 8978 | Medium/Full |

### Monitoring
| Stack | Porta local | Edição |
|---|---|---|
| `monitoring/grafana` | 3000 | Medium+ |
| `monitoring/prometheus` | 9090 | Medium+ |
| `monitoring/loki` | 3100 | Full |

### Automação
| Stack | Porta local | Edição |
|---|---|---|
| `automation/n8n` | 5678 | Medium+ |
| `automation/uptime-kuma` | 3001 | Medium+ |
| `automation/mailpit` | 8025 (UI) / 1025 (SMTP) | Medium+ |

### Storage
| Stack | Porta local | Edição |
|---|---|---|
| `storage/minio` | 9001 (API) / 9002 (console) | Medium+ |

### LLM / IA
| Stack | Porta local | Edição |
|---|---|---|
| `llm/open-webui` | 8080 | Full |
