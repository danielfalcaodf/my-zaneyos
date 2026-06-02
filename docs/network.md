# Guia de Rede, DNS e VPN — ZaneyOS Custom Fork

Este guia cobre toda a infraestrutura de rede do homelab: Blocky (DNS proxy),
Caddy (HTTPS reverse proxy com CA local), e Tailscale (VPN opcional).

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                       LAN (192.168.x.x)                     │
│                                                             │
│   Celular / outro PC                                        │
│        │                                                    │
│        │  DNS: portainer.homelab.lan ?                      │
│        ▼                                                    │
│   [Roteador]  ──── DNS primário → LAN IP do PC NixOS ────▶ │
│                                                             │
│   PC NixOS (192.168.x.y)                                   │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Blocky :53 (0.0.0.0)                           │      │
│   │    *.homelab.lan   →  LAN IP                    │      │
│   │    outros          →  Quad9 DoH                 │      │
│   │    ads/trackers    →  NXDOMAIN (bloqueado)      │      │
│   │                                                  │      │
│   │  Caddy :443/:80 (0.0.0.0)                       │      │
│   │    TLS: CA local (Caddy internal)               │      │
│   │    portainer.homelab.lan → 127.0.0.1:9000       │      │
│   │    home.homelab.lan      → 127.0.0.1:3003       │      │
│   │    ...                                          │      │
│   └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘

Acesso remoto (Tailscale — opcional):
   Dispositivo fora da rede
       │  WireGuard mesh (Tailscale)
       ▼
   PC NixOS  →  mesmo Blocky + Caddy
```

---

## Pré-requisitos

- **IP estático ou reserva DHCP** para o PC NixOS no roteador.
  Sem IP fixo, o LAN IP pode mudar e quebrar a resolução DNS.
- **Roteador com configuração de DNS personalizado** (praticamente todos suportam).

---

## Blocky — DNS Proxy

### O que faz

- Escuta na porta 53 em **todas as interfaces** (`0.0.0.0`) — qualquer dispositivo
  da rede pode usá-lo como DNS.
- Resolve `*.homelab.lan` para o LAN IP do PC NixOS (wildcard).
- Encaminha outros domínios para o Quad9 via **DNS-over-HTTPS** (privacidade).
- Bloqueia ads e trackers usando a lista StevenBlack.
- Expõe métricas Prometheus em `http://localhost:4000/metrics`.

### Verificar status

```bash
systemctl status blocky
journalctl -u blocky -f

# Testar resolução (do próprio host)
dig portainer.homelab.lan @127.0.0.1

# Testar de outro dispositivo
dig portainer.homelab.lan @<LAN_IP_DO_SERVIDOR>
```

### Configurar DNS no roteador

Acesse o painel do roteador e defina:

| Campo | Valor |
|---|---|
| DNS Primário | `<LAN IP do PC NixOS>` (ex: `192.168.1.100`) |
| DNS Secundário | `9.9.9.9` (fallback caso o Blocky fique offline) |

Após salvar, todos os dispositivos da rede passarão a resolver `*.homelab.lan`.

### Configurar DNS manualmente por dispositivo

Se não quiser alterar o roteador, configure o DNS em cada dispositivo:

**Windows:**
> Configurações → Rede → Adaptador → Propriedades → IPv4 → DNS: `<LAN IP>`

**macOS:**
> Preferências → Rede → Avançado → DNS → `+` → `<LAN IP>`

**iOS / iPadOS:**
> Ajustes → Wi-Fi → (rede) → Configurar DNS → Manual → `<LAN IP>`

**Android:**
> Ajustes → Wi-Fi → (segurar rede) → Modificar → Avançado → DNS: `<LAN IP>`

**Linux (systemd-resolved):**
```bash
resolvectl dns <interface> <LAN IP>
resolvectl domain <interface> homelab.lan
```

---

## Caddy — HTTPS Reverse Proxy

### TLS com CA local (Caddy internal)

O Caddy gera automaticamente uma **autoridade certificadora (CA) local** e
emite certificados para todos os virtual hosts na primeira inicialização.

Vantagens:
- Zero dependência externa — funciona totalmente offline.
- Sem Let's Encrypt (não precisa de porta 80 pública nem DNS-01).
- Renovação automática de certificados.
- HTTPS real em `homelab.lan` com lock verde no browser.

Desvantagem:
- Cada dispositivo precisa instalar o root CA uma única vez.

### Localização do root CA

```
/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

> **NUNCA distribua** o arquivo `root.key` (chave privada) — apenas `root.crt`.

### Copiar o cert para outro dispositivo

```bash
# Via SSH (do dispositivo destino)
scp <usuario>@<LAN_IP>:/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt ./homelab-root-ca.crt

# Ou copiar o conteúdo manualmente
cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

---

## Instalar o Root CA em cada dispositivo

Faça isso **uma única vez** por dispositivo para que o HTTPS apareça com lock verde.

### Windows

1. Copie `root.crt` para o PC Windows.
2. Duplo-clique → "Instalar certificado".
3. Selecione "Computador Local" → Avançar.
4. "Colocar todos os certificados no seguinte repositório" →
   "Autoridades de Certificação Raiz Confiáveis".
5. Finalizar → Sim (confirmar).
6. Reinicie o Chrome/Edge.

### macOS

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root.crt
```

Ou via Finder: duplo-clique → Acesso às Chaves → marcar como "Sempre Confiar".

### iOS / iPadOS

1. Transfira `root.crt` para o dispositivo (AirDrop, email, etc.).
2. Toque no arquivo → "Perfil Baixado" aparece em Ajustes.
3. Ajustes → Perfil Baixado → Instalar.
4. Ajustes → Geral → Sobre → Configurações de Confiança de Certificado.
5. Ative o toggle para o certificado do homelab.

### Android

1. Copie `root.crt` para o dispositivo.
2. Ajustes → Segurança → Instalação de certificados → Certificado CA.
3. Selecione o arquivo `root.crt`.
4. Dê um nome (ex: "Homelab CA") → OK.

> Em alguns Android: Ajustes → Biometria e segurança → Outras configurações de segurança.

### Linux (sistema — Debian/Ubuntu)

```bash
sudo cp root.crt /usr/local/share/ca-certificates/homelab-root-ca.crt
sudo update-ca-certificates
```

### Linux (NixOS)

```nix
# em configuration.nix ou num módulo:
security.pki.certificates = [
  (builtins.readFile /path/to/root.crt)
];
```

### Firefox (qualquer plataforma)

Firefox usa seu próprio store de certificados:

1. about:preferences#privacy → "Ver certificados".
2. Aba "Autoridades" → "Importar".
3. Selecione `root.crt`.
4. Marque "Confiar para sites" → OK.

### Chrome / Chromium (Linux)

```bash
# Instalar certutil (NSS tools)
nix-shell -p nssTools

# Adicionar ao Chrome
certutil -d sql:$HOME/.pki/nssdb -A -t "CT,," -n "Homelab CA" -i root.crt

# Adicionar ao Chromium
certutil -d sql:$HOME/.config/chromium/Default -A -t "CT,," -n "Homelab CA" -i root.crt
```

---

## Tailscale VPN (acesso remoto)

### Habilitar

Em `hosts/<hostname>/variables.nix`:

```nix
tailscaleEnable = true;
```

Reconstrua o sistema:

```bash
zcli rebuild
```

### Autenticar

```bash
# Autenticação interativa (abre URL no browser)
sudo tailscale up

# Com auth key (sem interação — crie em https://login.tailscale.com/admin/settings/keys)
sudo tailscale up --authkey=tskey-auth-XXXXXXXXXXXX
```

### Verificar conexão

```bash
tailscale status
tailscale ip -4   # IP Tailscale deste host
```

### Usar o homelab via VPN

Quando conectado via Tailscale, configure o DNS do dispositivo remoto
para o **Tailscale IP** do servidor (ex: `100.x.x.x`).

O Blocky responderá em `100.x.x.x:53` e resolverá `*.homelab.lan`.
O Caddy responderá em `100.x.x.x:443`.

### Tailscale split DNS (avançado)

No painel do Tailscale Admin (https://login.tailscale.com/admin/dns):

1. "Nameservers" → "Add nameserver" → Custom → `<Tailscale IP do servidor>`.
2. "Restrict to domain" → `homelab.lan`.

Isso faz dispositivos Tailscale resolverem `*.homelab.lan` via Blocky
sem precisar configurar DNS manualmente.

---

## No-IP DDNS (acesso externo — futuro)

O roteador suporta No-IP para atualizar o IP público automaticamente.
Isso é reservado para **uso futuro** quando quiser expor serviços via internet.

Opções para acesso externo:

| Opção | Requisitos | Notas |
|---|---|---|
| Port forward 443 | Roteador + No-IP DDNS | HTTPS, requer IP público dinâmico |
| Cloudflare Tunnel | Conta Cloudflare grátis | Zero port forward, TLS via Cloudflare |
| Tailscale (já config) | Auth key | Sem exposição pública, mais seguro |

Não configure `noIpHostname` para ACME — No-IP não suporta DNS-01 e
Let's Encrypt HTTP-01 requer porta 80 pública.

---

## Comandos de verificação

```bash
# Status completo: DNS, Caddy, Blocky, Tailscale
zcli net-status

# Status individual dos serviços
systemctl status blocky
systemctl status caddy
systemctl status tailscaled

# DNS resolution tests
dig portainer.homelab.lan @127.0.0.1
dig portainer.homelab.lan @<LAN_IP>

# HTTPS test
curl -sv https://portainer.homelab.lan 2>&1 | grep -E "SSL|HTTP|Connected"

# Ver IP LAN atual
ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}'

# Ver root CA
cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

---

## Troubleshooting

### DNS não resolve de outro dispositivo

1. Verifique se o dispositivo está usando o LAN IP do servidor como DNS:
   ```bash
   # No dispositivo: verifique o DNS configurado
   nslookup portainer.homelab.lan
   ```
2. Verifique se o Blocky está rodando e ouvindo na porta 53:
   ```bash
   systemctl status blocky
   ss -tlunp | grep :53
   ```
3. Verifique o firewall:
   ```bash
   sudo iptables -L INPUT -n | grep 53
   ```

### HTTPS mostra aviso de certificado

O root CA do Caddy ainda não foi instalado no dispositivo.
Siga as instruções de instalação acima para a plataforma correspondente.

### Caddy não inicia

```bash
journalctl -u caddy -f
# Causas comuns:
ss -tlnp | grep :443   # porta ocupada?
ss -tlnp | grep :80    # porta ocupada?
```

### Blocky conflito de porta 53

O `systemd-resolved` tem um stub listener em `127.0.0.53:53`.
O módulo `blocky.nix` configura `DNSStubListener = "no"` para evitar conflito.
Verifique:

```bash
resolvectl status | grep "DNS Stub Listener"
# Deve mostrar: no
```

### Tailscale não conecta

```bash
journalctl -u tailscaled -f
sudo tailscale up --reset   # reset de configuração
```

### LAN IP mudou (DHCP sem reserva)

1. Atualize `lanIP` em `hosts/<hostname>/variables.nix`.
2. Reconstrua: `zcli rebuild`.
3. Recomende: configure reserva DHCP no roteador pelo MAC address do PC.

---

## Configuração em `variables.nix`

```nix
# Domínio local (evite .local — conflito com mDNS)
localDomain = "homelab.lan";

# IP LAN deste PC (defina como estático ou reserva DHCP no roteador)
lanIP = "192.168.1.100";

# Interface de rede principal
networkInterface = "enp3s0";

# Tailscale VPN
tailscaleEnable = false;

# No-IP hostname (reservado para uso futuro com acesso externo)
noIpHostname = "";
```
