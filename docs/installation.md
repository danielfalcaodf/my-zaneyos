# Guia de Instalação — ZaneyOS Custom Fork

> Fork pessoal do [ZaneyOS](https://gitlab.com/zaney/zaneyos) (Tyler Kelley).
> Adiciona edições (vm / basic / medium / full), homelab Docker stacks e ferramentas de desenvolvimento.

---

## Pré-requisitos

| Requisito | Detalhe |
|---|---|
| Sistema operacional | NixOS 24.05 ou mais recente |
| Particionamento | GPT com boot UEFI |
| Boot loader | systemd-boot (GRUB não suportado) |
| Partição `/boot` | Mínimo 500 MB |
| Armazenamento | Veja tabela por edição abaixo |
| Conectividade | Internet disponível durante a instalação |

### Requisitos de armazenamento por edição

| Edição | Mínimo | Recomendado | Observações |
|---|---|---|---|
| `vm` | 40 GB | 60 GB | Sem modelos LLM, sem SQL Server |
| `basic` | 80 GB | 120 GB | Espaço para volumes Docker |
| `medium` | 150 GB | 250 GB | Bancos + imagens Docker |
| `full` | 250 GB | 500 GB–1 TB | Ollama (opcional) + todos os stacks |

---

## Instalação automatizada (recomendada)

### 1. Entrar no ambiente com dependências

```bash
nix-shell -p git curl pciutils
```

### 2. Executar o script de instalação deste fork

```bash
sh <(curl -L https://raw.githubusercontent.com/danielfalcaodf/my-zaneyos/main/install-zaneyos.sh)
```

O script irá:
1. Detectar automaticamente o perfil de GPU (`amd`, `nvidia`, `intel`, `vm`, etc.)
2. Perguntar o hostname da máquina
3. **Perguntar a edição:** `vm` / `basic` / `medium` / `full`
4. Perguntar nome de usuário Git, e-mail, fuso horário e layout de teclado
5. Criar o diretório do host em `hosts/<hostname>/`
6. Gerar o `hardware.nix` via `nixos-generate-config`
7. Realizar o primeiro build com `nixos-rebuild boot`

> **⚠️ Atenção:** O `hardware.nix` gerado contém informações específicas do seu hardware.
> Ele está no `.gitignore` — nunca o versione em um repositório público.

### 3. Reiniciar

```bash
reboot
```

---

## Instalação manual (avançada)

### 1. Instalar dependências temporárias

```bash
nix-shell -p git vim
```

### 2. Clonar o repositório

```bash
cd ~ && git clone https://github.com/danielfalcaodf/my-zaneyos.git -b main --depth=1 ~/zaneyos
cd ~/zaneyos
```

### 3. Criar o diretório do host

```bash
cp -r hosts/default hosts/<seu-hostname>
git add hosts/<seu-hostname>/
```

### 4. Editar `variables.nix`

```bash
vim hosts/<seu-hostname>/variables.nix
```

Campos obrigatórios a preencher:

```nix
{
  # Identidade
  gitUsername = "Seu Nome";
  gitEmail = "seu@email.com";

  # Edição: "vm" | "basic" | "medium" | "full"
  edition = "basic";

  # Localização
  timeZone = "America/Sao_Paulo";
  locale = "pt_BR.UTF-8";

  # Teclado
  keyboardLayout = "br";
  keyboardVariant = "abnt2";
  consoleKeyMap = "br-abnt2";

  # Restante: ajuste conforme preferência
}
```

### 5. Gerar o hardware.nix

```bash
nixos-generate-config --show-hardware-config > hosts/<seu-hostname>/hardware.nix
```

> **⚠️ Não versione este arquivo.** Ele já está no `.gitignore`.

### 6. Atualizar referências no flake.nix

Edite `flake.nix` para apontar para o seu host:

```nix
# Exemplo: adicionar uma entrada usando seu GPU profile
nixosConfigurations = {
  # ... entradas existentes ...
  meu-host = mkNixosConfig {
    gpuProfile = "amd";           # amd | nvidia | nvidia-laptop | intel | vm
    host = "<seu-hostname>";
    username = "<seu-username>";
  };
};
```

### 7. Fazer o primeiro build

```bash
NIX_CONFIG="experimental-features = nix-command flakes"
sudo nixos-rebuild boot --flake .#meu-host
reboot
```

---

## Verificação pós-instalação

Após o reboot, execute o diagnóstico:

```bash
zcli diag
```

Verifique se o Caddy está rodando (edições basic/medium/full):

```bash
systemctl status caddy
curl -I http://portainer.localhost
```

Verifique o DNS local:

```bash
nslookup portainer.localhost
# Deve resolver para 127.0.0.1
```

---

## Usando os Docker Stacks

Todos os stacks ficam em `~/zaneyos/docker/stacks/`. Para iniciar um stack:

```bash
cd ~/zaneyos/docker/stacks/databases/postgres
cp .env.example .env
# Edite .env com suas senhas reais
docker compose up -d
```

> Veja [docs/docker-stacks.md](docker-stacks.md) para a referência completa de todos os stacks.

---

## Instalar NVM e SDKMAN (pós-instalação)

O NixOS configura o ambiente para recebê-los, mas eles devem ser instalados manualmente uma vez:

```bash
# NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# SDKMAN (Java/JVM)
curl -s "https://get.sdkman.io" | bash
```

Reinicie o terminal após instalar. O `mise` já está disponível via Nix e funciona como fallback global.

> Veja [docs/dev-tools.md](dev-tools.md) para o guia completo de coexistência NVM/SDKMAN/mise.

---

## Atualizar o sistema

```bash
# Rebuild + atualizar flake inputs
zcli update

# Apenas rebuild (sem atualizar inputs)
zcli rebuild

# Ver gerações disponíveis
zcli list-gens

# Remover gerações antigas
zcli cleanup
```

---

## Troubleshooting

### Build falha por flake check

```bash
nix flake check --show-trace
```

### Hardware.nix não detecta GPU

```bash
nix-shell -p pciutils --run "lspci | grep -i vga"
```

### Caddy não inicia

```bash
journalctl -u caddy -f
# Se porta 80 estiver ocupada:
ss -tlnp | grep :80
```

### DNS local não resolve

```bash
# Verificar se NetworkManager usa dnsmasq
resolvectl status
# Deve mostrar dnsmasq como backend
```
