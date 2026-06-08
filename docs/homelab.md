# Guia de Homelab — ZaneyOS Custom Fork

Este guia explica a arquitetura do homelab local: Blocky como DNS proxy,
Caddy como reverse proxy HTTPS, e como usar os Docker stacks.

---

## Arquitetura

```
Celular / outro PC na rede local
    │
    │  DNS query: portainer.homelab.lan ?
    ▼
[Blocky :53  — 0.0.0.0]         ← módulo NixOS (blocky.nix)
    │  *.homelab.lan → LAN IP do servidor
    │  outras queries → Quad9 DoH (https://dns.quad9.net)
    │  blocklists de ads (StevenBlack)
    ▼
[Caddy :443/:80  — 0.0.0.0]     ← módulo NixOS (caddy.nix)
    │  TLS: CA local (Caddy internal CA — local_certs)
    │  HTTP :80 → redireciona para HTTPS :443
    │
    ├── home.homelab.lan          →  127.0.0.1:3003  (Homepage)
    ├── portainer.homelab.lan     →  127.0.0.1:9000  (Portainer)
    ├── db.homelab.lan            →  127.0.0.1:8082  (Adminer)
    ├── cloudbeaver.homelab.lan   →  127.0.0.1:8978  (CloudBeaver)
    ├── grafana.homelab.lan       →  127.0.0.1:3000  (Grafana)
    ├── prometheus.homelab.lan    →  127.0.0.1:9090  (Prometheus)
    ├── n8n.homelab.lan           →  127.0.0.1:5678  (n8n)
    ├── uptime.homelab.lan        →  127.0.0.1:3001  (Uptime Kuma)
    ├── mail.homelab.lan          →  127.0.0.1:8025  (Mailpit)
    ├── woodpecker.homelab.lan    →  127.0.0.1:8000  (Woodpecker CI)
    ├── minio.homelab.lan         →  127.0.0.1:9001  (MinIO)
    └── openwebui.homelab.lan     →  127.0.0.1:8080  (Open WebUI)

Acesso remoto (Tailscale VPN — opcional):
    Dispositivo remoto
        │ WireGuard mesh (Tailscale)
        ▼
    PC NixOS → mesmo Blocky + Caddy
```

**Configurar no roteador (único passo manual):**
Defina o DNS primário do roteador como o IP LAN do PC NixOS (ex: `192.168.1.100`).
Isso faz todos os dispositivos da rede usarem o Blocky automaticamente.

**Por dispositivo (uma única vez):**
Instale o root CA certificate do Caddy em cada dispositivo — veja [docs/network.md](network.md).

> O domínio `homelab.lan` é configurável em `variables.nix` (`localDomain`).
> O `.lan` evita conflitos com mDNS/Bonjour (`.local` é reservado).

---

## Caddy (reverse proxy HTTPS)

O módulo `modules/core/caddy.nix` configura o Caddy como serviço NixOS com
HTTPS automático via CA interna (`local_certs`). Ativado nas edições `basic`,
`medium` e `full`.

```bash
# Verificar status
systemctl status caddy

# Ver logs
journalctl -u caddy -f

# Testar acesso (após instalar o root CA no dispositivo)
curl -I https://portainer.homelab.lan

# Caminho do root CA certificate
ls /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

---

## Blocky (DNS proxy LAN)

O módulo `modules/core/blocky.nix` substitui o dnsmasq anterior.
Escuta em `0.0.0.0:53` — qualquer dispositivo na rede pode usá-lo.

```bash
# Verificar status
systemctl status blocky

# Testar resolução DNS (do próprio host)
dig portainer.homelab.lan @127.0.0.1

# Testar de outro dispositivo (substitua pelo IP LAN do servidor)
dig portainer.homelab.lan @192.168.1.100

# Métricas (Prometheus) — porta 4000
curl http://localhost:4000/metrics
```

### Configurar DNS no roteador

Acesse o painel do roteador e defina:
- **DNS primário:** `<LAN IP do PC NixOS>` (ex: `192.168.1.100`)
- **DNS secundário:** `9.9.9.9` (fallback)

---

## Portainer

Stack: `docker/stacks/homelab/portainer/`

```bash
cd ~/zaneyos/docker/stacks/homelab/portainer
cp .env.example .env
docker compose up -d
```

Acesse em: https://portainer.homelab.lan

Na primeira inicialização o Portainer pedirá para criar um usuário admin.

---

## Homepage (dashboard)

Stack: `docker/stacks/homelab/homepage/`

```bash
zstack init homelab/homepage
# Edite o .env com os hosts permitidos
nano docker/stacks/homelab/homepage/.env
# Configure serviços (copie o exemplo e personalize):
cp docker/stacks/homelab/homepage/config/services.yaml.example docker/stacks/homelab/homepage/config/services.yaml
nano docker/stacks/homelab/homepage/config/services.yaml
zstack up homelab/homepage
```

Acesse em: https://home.homelab.lan

Personalize serviços em `config/services.yaml` (use `services.yaml.example` como template), bookmarks em `config/bookmarks.yaml`, e widgets em `config/widgets.yaml`.
Veja a documentação completa em: https://gethomepage.dev

> **Erro "Host validation failed"?** Configure `HOMEPAGE_ALLOWED_HOSTS` no `.env`.
> Veja: [`docs/docker-stacks.md`](docker-stacks.md) — seção Homepage.

---

## Woodpecker CI

Stack: `docker/stacks/automation/woodpecker/`

Plataforma de CI/CD open source para automatizar pipelines de build e teste.

```bash
zstack init automation/woodpecker
nano docker/stacks/automation/woodpecker/.env
zstack up automation/woodpecker
```

Veja o guia completo em: [`docs/woodpecker-ci.md`](woodpecker-ci.md)

---

## Regras de segurança

1. **Nunca exponha bancos na rede** — use apenas `127.0.0.1:PORT:PORT`
2. **Nunca commite `.env`** — apenas `.env.example` fica no repositório
3. **Use senhas fortes** — substitua todos os `changeme` no `.env` antes de usar
4. **Firewall** — portas 22, 53, 80, 443 abertas; bancos NÃO abertos no firewall
5. **SSH key-only** — configurado em `modules/core/services.nix`
6. **Root CA** — não distribua a chave privada (`root.key`); apenas o cert público (`root.crt`)

---

## Referência rápida de URLs

| Serviço | URL local |
|---|---|
| Homepage | https://home.homelab.lan |
| Portainer | https://portainer.homelab.lan |
| Adminer | https://db.homelab.lan |
| CloudBeaver | https://cloudbeaver.homelab.lan |
| Grafana | https://grafana.homelab.lan |
| Prometheus | https://prometheus.homelab.lan |
| n8n | https://n8n.homelab.lan |
| Uptime Kuma | https://uptime.homelab.lan |
| Mailpit | https://mail.homelab.lan |
| Woodpecker CI | https://woodpecker.homelab.lan |
| MinIO | https://minio.homelab.lan |
| Open WebUI | https://openwebui.homelab.lan |

> O domínio `homelab.lan` pode ser trocado em `hosts/<hostname>/variables.nix` (`localDomain`).
> Veja [docs/network.md](network.md) para o guia completo de rede, TLS e VPN.
