# HTTPS Local com Caddy (Local CA)

Este documento explica como configurar HTTPS local para todos os serviços do homelab sem alertas de segurança no navegador.

## Como Funciona

O Caddy usa sua **própria CA interna** (`local_certs`) para gerar certificados TLS automaticamente para todos os domínios `*.homelab.lan`.

- **Root CA**: `/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`
- **Certificados**: Gerados automaticamente no primeiro acesso
- **Renovação**: Automática pelo Caddy

## Instalação do Root CA nos Dispositivos

### Linux (Chrome/Chromium/Firefox)

```bash
# Copiar certificado para confiança do sistema
sudo cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt \
  /usr/local/share/ca-certificates/zaneyos-root.crt
sudo update-ca-certificates

# Para Firefox (usa store próprio)
# 1. Abrir about:preferences#privacy
# 2. Certificados > Ver certificados > Autoridades > Importar
# 3. Selecionar root.crt e marcar "Confiar para identificar sites"
```

### Linux (trust store nativo - systemd)

```bash
sudo trust anchor --store /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

### macOS

```bash
# Via keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

### Windows

```powershell
# PowerShell como Admin
Import-Certificate -FilePath "C:\path\to\root.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### Android

1. Copiar `root.crt` para o dispositivo
2. Configurações > Segurança > Credenciais > Instalar certificado > CA
3. Selecionar o arquivo

### iOS

1. Enviar `root.crt` por AirDrop/email
2. Instalar perfil em Configurações > Geral > VPN e Gerenciamento de Dispositivo
3. Ativar confiança total: Configurações > Geral > Sobre > Confiança de Certificados

## Verificação

Após instalar o Root CA:

```bash
# Testar resolução DNS
dig @127.0.0.1 portainer.homelab.lan

# Testar HTTPS
curl -I https://portainer.homelab.lan
# Deve retornar HTTP/2 200 ou 302 (sem erro de certificado)
```

## Troubleshooting

### Certificado não gerado
```bash
# Verificar logs do Caddy
journalctl -u caddy -f

# Verificar se Caddy tem permissão no diretório
ls -la /var/lib/caddy/.local/share/caddy/pki/authorities/local/
```

### Navegador ainda avisa
- Limpar cache SSL do navegador (chrome://net-internals/#hsts)
- Reiniciar navegador
- Verificar se Root CA está em "Autoridades de Certificação Raiz Confiáveis"

### Blocky não resolve *.homelab.lan
```bash
# Verificar se Blocky está rodando
systemctl status blocky

# Testar resolução direta no Blocky
dig @127.0.0.1 portainer.homelab.lan

# Verificar configuração em /etc/resolv.conf
cat /etc/resolv.conf
# Deve conter: nameserver 127.0.0.1
```

## Rotas Configuradas

| Serviço | URL | Porta Interna |
|---------|-----|---------------|
| Homepage | https://home.homelab.lan | 3003 |
| Portainer | https://portainer.homelab.lan | 9000 |
| Adminer (DB) | https://db.homelab.lan | 8083 |
| CloudBeaver | https://cloudbeaver.homelab.lan | 8979 |
| Grafana | https://grafana.homelab.lan | 3000 |
| Prometheus | https://prometheus.homelab.lan | 9090 |
| n8n | https://n8n.homelab.lan | 5678 |
| Uptime Kuma | https://uptime.homelab.lan | 3001 |
| Mailpit | https://mail.homelab.lan | 8025 |
| Woodpecker CI | https://woodpecker.homelab.lan | 8000 |
| MinIO | https://minio.homelab.lan | 9001 |
| Docker Registry | https://registry.homelab.lan | 5000 |
| DNS Manager | https://dns.homelab.lan | 5380 |
| Open WebUI | https://openwebui.homelab.lan | 8080 |

## Portas do Firewall

Certifique-se de que as portas 80 e 443 estão abertas no firewall do NixOS:

```nix
networking.firewall.allowedTCPPorts = [80 443];
```

## Renovação Automática

O Caddy renova certificados automaticamente 30 dias antes do vencimento. Não é necessário intervenção manual.

## Backup do Root CA

```bash
# Backup seguro do Root CA
cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt ~/backups/zaneyos-root-$(date +%Y%m%d).crt
cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.key ~/backups/zaneyos-root-$(date +%Y%m%d).key
# IMPORTANTE: Guarde a chave privada (root.key) em local seguro!
```