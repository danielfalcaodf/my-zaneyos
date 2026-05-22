# Guia de Homelab — ZaneyOS Custom Fork

Este guia explica a arquitetura do homelab local: Caddy como reverse proxy,
DNS local para `.localhost`, e como usar os Docker stacks.

---

## Arquitetura

```
Navegador
   │
   ▼  http://portainer.localhost
[Caddy :80]  ◄── NixOS module (caddy.nix)
   │
   ├── portainer.localhost  →  127.0.0.1:9000  (Portainer)
   ├── db.localhost         →  127.0.0.1:8082  (Adminer)
   ├── cloudbeaver.localhost→  127.0.0.1:8978  (CloudBeaver)
   ├── n8n.localhost        →  127.0.0.1:5678  (n8n)
   ├── uptime.localhost     →  127.0.0.1:3001  (Uptime Kuma)
   ├── mail.localhost       →  127.0.0.1:8025  (Mailpit)
   ├── minio.localhost      →  127.0.0.1:9001  (MinIO)
   ├── grafana.localhost    →  127.0.0.1:3000  (Grafana)
   └── home.localhost       →  127.0.0.1:3003  (Homepage)

[NetworkManager + dnsmasq]  ◄── NixOS module (dns.nix)
   └── *.localhost  →  127.0.0.1
```

> Todos os serviços ficam **somente em loopback** (`127.0.0.1`).
> Nenhum banco ou serviço é exposto na rede local.

---

## Caddy (reverse proxy)

### Via NixOS (recomendado — edições basic/medium/full)

O módulo `modules/core/caddy.nix` configura o Caddy como serviço NixOS.
Ele é ativado automaticamente nas edições `basic`, `medium` e `full`.

```bash
# Verificar status
systemctl status caddy

# Ver logs
journalctl -u caddy -f

# Testar acesso
curl -I http://portainer.localhost
```

### Via Docker (opcional — quando não usar o módulo NixOS)

Use o stack em `docker/stacks/homelab/caddy/`:

```bash
cd ~/zaneyos/docker/stacks/homelab/caddy
cp Caddyfile.example Caddyfile
docker compose up -d
```

> O `Caddyfile` já está no `.gitignore`. Personalize sem medo de versionamento acidental.

---

## DNS Local (`.localhost`)

### Via NixOS (recomendado — edições basic/medium/full)

O módulo `modules/core/dns.nix` configura o dnsmasq integrado ao NetworkManager.
Todos os domínios `*.localhost` resolvem para `127.0.0.1` automaticamente.

```bash
# Verificar que o dnsmasq está ativo
resolvectl status | grep -A3 "DNS Servers"

# Testar resolução
nslookup portainer.localhost
# Resposta esperada: 127.0.0.1
```

### Adicionar domínios customizados

Para resolver domínios além de `*.localhost`, crie um arquivo em:
`/etc/NetworkManager/dnsmasq.d/custom.conf`

```
# Exemplo: resolver minhaapp.local para um servidor na rede
address=/minhaapp.local/192.168.1.10
```

---

## Portainer

Stack: `docker/stacks/homelab/portainer/`

```bash
cd ~/zaneyos/docker/stacks/homelab/portainer
cp .env.example .env
docker compose up -d
```

Acesse em: http://portainer.localhost (via Caddy) ou http://localhost:9000

Na primeira inicialização o Portainer pedirá para criar um usuário admin.

---

## Homepage (dashboard)

Stack: `docker/stacks/homelab/homepage/`

```bash
cd ~/zaneyos/docker/stacks/homelab/homepage
cp config/settings.yaml.example config/settings.yaml
docker compose up -d
```

Acesse em: http://home.localhost

Personalize adicionando serviços em `config/services.yaml` e `config/bookmarks.yaml`.
Veja a documentação completa em: https://gethomepage.dev

---

## Regras de segurança

1. **Nunca exponha bancos na rede** — use apenas `127.0.0.1:PORT:PORT`
2. **Nunca commite `.env`** — apenas `.env.example` fica no repositório
3. **Use senhas fortes** — substitua todos os `changeme` no `.env` antes de usar
4. **Firewall** — portas 22, 80, 443 abertas; bancos NÃO abertos no firewall
5. **SSH key-only** — configurado em `modules/core/services.nix`

---

## Referência rápida de URLs

| Serviço | URL local |
|---|---|
| Portainer | http://portainer.localhost |
| Adminer | http://db.localhost |
| CloudBeaver | http://cloudbeaver.localhost |
| n8n | http://n8n.localhost |
| Uptime Kuma | http://uptime.localhost |
| Mailpit | http://mail.localhost |
| MinIO Console | http://minio.localhost |
| Grafana | http://grafana.localhost |
| Homepage | http://home.localhost |
