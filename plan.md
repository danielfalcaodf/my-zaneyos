# Plano de Ação — ZaneyOS Personalizado

---

## STATUS — Progresso por Fase

> Última atualização: 2026-05-22 | Branch: `feat/devdaniel-homelab-editions`

### ✅ Phase 0 — Foundation (COMPLETA)

- [x] `README.md` — atribuição ao fork original (ZaneyOS / Tyler Kelley)
- [x] `.gitignore` — regras para `.env`, `hardware.nix` reais, `result`, logs
- [x] `install-zaneyos.sh` — clone URL atualizado, pergunta de `edition`, patch de `timeZone`/`locale`/`edition` no `variables.nix`
- [x] `modules/core/services.nix` — SSH hardened (`PasswordAuthentication = false`, `KbdInteractiveAuthentication = false`)
- [x] `modules/core/system.nix` — `timeZone` e `locale` lidos do `variables.nix` (com fallback)
- [x] `modules/core/boot.nix` — Plymouth condicional (`edition != "vm"`)
- [x] `hosts/default/variables.nix` — campos `edition`, `timeZone`, `locale` adicionados
- [x] `hosts/zaneyos-24-vm/variables.nix` — idem
- [x] `hosts/zaneyos-oem/variables.nix` — idem

---

### ✅ Phase 1 — Editions Structure (COMPLETA)

- [x] `modules/editions/vm.nix` — sem Plymouth, Docker desabilitado (`mkForce false`)
- [x] `modules/editions/basic.nix` — ferramentas dev base (git, gh, delta, just, direnv, mise, node, python, LSPs)
- [x] `modules/editions/medium.nix` — importa basic + cloud tools (k8s, terraform, awscli, gcloud, dbeaver, redis, zellij)
- [x] `modules/editions/full.nix` — importa medium + k3d, aichat, distrobox
- [x] `modules/core/default.nix` — importa `editionModule` via `vars.edition`
- [x] `modules/core/virtualisation.nix` — Docker com `mkDefault true` (permite override por edição)
- [x] `modules/home/editions/default.nix` — importa `dev-tools.nix` (exceto vm)
- [x] `modules/home/editions/dev-tools.nix` — init de NVM/SDKMAN/mise no shell (ZSH)
- [x] `modules/home/editors/vscode.nix` — extensões LSP/dev adicionadas
- [x] `dev-tools.nix` para fish shell — `programs.fish.interactiveShellInit` adicionado (NVM env vars + mise activate fish)
- [ ] `nix flake check` — nomes de pacotes a confirmar (`mysql80`, `postgresql_client`, `dbeaver-bin`, `biome`, etc.)

---

### ✅ Phase 2 — Docker Stacks (COMPLETA)

#### Databases
- [x] `docker/stacks/databases/postgres/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/databases/mysql/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/databases/sqlserver/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/databases/redis/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/databases/adminer/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/databases/cloudbeaver/` — `.env.example` + `compose.yml`

#### Homelab
- [x] `docker/stacks/homelab/portainer/` — `.env.example` + `compose.yml`
- [x] `docker/stacks/homelab/caddy/` — compose.yml + Caddyfile.example + .env.example criados
- [x] `docker/stacks/homelab/homepage/` — compose.yml + config/settings.yaml.example criados

#### Monitoring
- [x] `docker/stacks/monitoring/grafana/` — compose.yml + .env.example criados
- [x] `docker/stacks/monitoring/prometheus/` — compose.yml + prometheus.yml.example criados
- [x] `docker/stacks/monitoring/loki/` — compose.yml criado

#### Automation
- [x] `docker/stacks/automation/n8n/` — `.env.example` criado
- [x] `docker/stacks/automation/n8n/compose.yml` — criado (com postgres integrado)
- [x] `docker/stacks/automation/uptime-kuma/` — compose.yml criado
- [x] `docker/stacks/automation/mailpit/` — compose.yml criado

#### Storage
- [x] `docker/stacks/storage/minio/` — `.env.example` criado
- [x] `docker/stacks/storage/minio/compose.yml` — criado

#### LLM
- [x] `docker/stacks/llm/open-webui/` — `.env.example` criado
- [x] `docker/stacks/llm/open-webui/compose.yml` — criado

---

### ✅ Phase 3 — Caddy Reverse Proxy (COMPLETA via NixOS)

- [x] `modules/core/caddy.nix` — serviço Caddy criado como módulo NixOS
- [x] Integração via `modules/editions/basic.nix` — importado corretamente (design por edição, não direto no core)

---

### ✅ Phase 4 — DNS Local (COMPLETA via NixOS)

- [x] `modules/core/dns.nix` — dnsmasq configurado como módulo NixOS
- [x] Integração via `modules/editions/basic.nix` — importado corretamente (vm edition não recebe DNS local)

---

### ✅ Phase 5 — Documentação (COMPLETA)

- [x] `docs/editions.md` — guia de edições com matriz completa de recursos
- [x] `docs/homelab.md` — guia de homelab (Caddy, DNS, Portainer, Homepage, segurança)
- [x] `docs/dev-tools.md` — guia NVM/SDKMAN/mise com coexistência e fish shell
- [x] `docs/docker-stacks.md` — referência completa com portas, URLs e instruções
- [x] `docs/installation.md` — guia de instalação completo (automatizado + manual + pós-install)
- [x] `README.md` — Fork docs links, seção Editions com matriz, requisitos de storage, Installation atualizado
- [x] `docker/stacks/README.md` — portas corrigidas (Grafana 3000, Loki 3100, Adminer 8082), homepage adicionada

---

### 📋 Critérios de Aceite

- [ ] `nix flake check` passa sem erros
- [x] Perfis GPU originais (amd/nvidia/etc.) ainda compilam
- [x] Desktop Hyprland com Stylix, Waybar/Noctalia, Rofi, SwayNC intactos
- [x] `variables.nix` backwards-compatible (hosts existentes não quebram)
- [x] SSH: `PasswordAuthentication = no` + `PermitRootLogin = no`
- [x] Nenhum banco exposto em `0.0.0.0`
- [x] `.env` não versionado, apenas `.env.example`
- [x] `hardware.nix` real não versionado (apenas template)
- [x] VS Code disponível via `vscodeEnable = true`
- [x] NVM/SDKMAN: inicializados no fish shell sem conflito com mise (env vars + mise activate fish)
- [x] Edição VM: Plymouth desabilitado, sem serviços pesados
- [x] Edição Full: Ollama opcional (comentado em `full.nix`, não baixa modelos por padrão)

---

## 1. Diagnóstico da Estrutura Atual

### flake.nix
- Usa `nixos-unstable` + `home-manager` + `stylix` + `nix-flatpak` + `noctalia` + `nixvim` + `nvf` + `antigravity-nix` + `zen-browser` + `alejandra` + `awww`
- Variáveis fixas no topo: `host = "zaneyos-24-vm"`, `profile = "vm"`, `username = "dwilliams"`
- `mkNixosConfig gpuProfile` cria cada nixosConfiguration passando o profile de GPU via `./profiles/${gpuProfile}`
- **Problema atual**: `host`, `username` e `profile` são hardcoded — precisam ser parametrizáveis por nixosConfiguration
- `nixosConfigurations` atual: `amd | nvidia | nvidia-laptop | amd-nvidia-hybrid | intel | vm` (nomenclatura = profile GPU, não edição)

### hosts/
```
hosts/
  default/            ← template base
  zaneyos-24-vm/      ← host VM de referência (hardware real hardcoded)
  zaneyos-oem/        ← outro host real
```
Cada host tem: `default.nix`, `hardware.nix`, `host-packages.nix`, `variables.nix`

**Variables.nix expõe:**
- `gitUsername`, `gitEmail`
- `displayManager` ("tui" | "sddm")
- `tmuxEnable`, `alacrittyEnable`, `weztermEnable`, `ghosttyEnable`, `vscodeEnable`, `antigravityEnable`, `helixEnable`, `doomEmacsEnable`
- `pythonEnable`
- `extraMonitorSettings`
- `barChoice` ("noctalia" | "waybar"), `clock24h`, `waybarChoice`, `animChoice`
- `browser`, `terminal`
- `keyboardLayout`, `keyboardVariant`, `consoleKeyMap`
- `intelID`, `amdgpuID`, `nvidiaID`
- `enableNFS`, `printEnable`, `thunarEnable`
- `stylixImage`
- `hostId`

### profiles/ (GPU — NÃO confundir com edições)
```
profiles/amd/           → drivers.amdgpu.enable = true
profiles/intel/
profiles/nvidia/
profiles/nvidia-laptop/
profiles/amd-nvidia-hybrid/
profiles/vm/            → vm.guest-services.enable = true, todos GPU false
```
Cada profile importa: `hosts/${host}` + `modules/drivers` + `modules/core`

### modules/core/
| Arquivo | Papel |
|---|---|
| `boot.nix` | Plymouth habilitado, systemd-boot, kernelPackages_latest |
| `network.nix` | hostname via `host`, firewall básico (22/80/443/8080) |
| `services.nix` | SSH (PasswordAuthentication=true!), pipewire, smartd, blueman |
| `security.nix` | rtkit, polkit, pam swaylock |
| `packages.nix` | Pacotes base do sistema (docker-compose, awww, brave, etc.) |
| `virtualisation.nix` | Docker=true, podman=false, libvirtd=true, vbox=false |
| `stylix.nix` | Lê `stylixImage` do variables.nix |
| `user.nix` | Home Manager, grupos do usuário (docker, libvirtd, wheel...) |
| `system.nix` | Locale en_US, timezone America/New_York, stateVersion 23.11 |
| `default.nix` | Importa todos acima, condiciona display manager |

### modules/home/
| Módulo | Papel |
|---|---|
| `hyprland/` | Binds, env, exec-once, animações, hypridle, hyprlock, windowrules |
| `waybar/` | 20+ temas de waybar, scripts associados |
| `noctalia.nix` | Shell noctalia alternativa ao waybar |
| `rofi/` | Launcher |
| `swaync/` | Notification center |
| `wlogout/` | Logout screen |
| `stylix.nix` | Theming home-manager |
| `editors/` | vscode.nix, nixvim.nix, helix, doom-emacs, nano, antigravity |
| `terminals/` | kitty, ghostty, wezterm, alacritty, tmux |
| `cli/` | bat, btop, bottom, cava, fzf, gh, git, htop, lazygit |
| `scripts/` | zcli, wallsetter, screenshootin, etc. |
| `python.nix` | Python dev tools |

### Observações críticas
- SSH tem `PasswordAuthentication = true` — **deve ser corrigido para key-only**
- Plymouth habilitado globalmente — deve ser desabilitado na edição VM
- `timezone` hardcoded como `America/New_York` — deve virar variável
- `locale` hardcoded como `en_US.UTF-8` — deve virar variável
- `host/username/profile` hardcoded no topo do flake.nix — não escala para múltiplos hosts
- `vscodeEnable` já existe em variables.nix — VS Code já suportado
- Docker já habilitado em `virtualisation.nix`

---

## 2. O Que Preservar (intocável)

- `modules/home/hyprland/` — todos os arquivos
- `modules/home/waybar/` — todos os temas
- `modules/home/noctalia.nix`
- `modules/home/rofi/`
- `modules/home/swaync/`, `swaync.nix`
- `modules/home/wlogout/`
- `modules/home/stylix.nix`
- `modules/core/stylix.nix`
- `wallpapers/` — toda a pasta
- `profiles/amd|intel|nvidia|nvidia-laptop|amd-nvidia-hybrid|vm/` — todos os profiles GPU
- `modules/drivers/` — drivers existentes
- `modules/home/scripts/` — scripts existentes
- `hosts/default/variables.nix` — estrutura base de variáveis

---

## 3. O Que Pode Ser Modificado (com cuidado)

| Arquivo | Modificação Proposta |
|---|---|
| `flake.nix` | Parametrizar host/username/edition por nixosConfiguration |
| `modules/core/services.nix` | SSH key-only, portas por edição |
| `modules/core/boot.nix` | Plymouth condicional por edição |
| `modules/core/system.nix` | Timezone/locale via variables.nix |
| `modules/core/packages.nix` | Modularizar pacotes por camada |
| `modules/core/virtualisation.nix` | Condicionar por edição |
| `hosts/default/variables.nix` | Adicionar novos toggles de edição |

---

## 4. Nova Arquitetura de Camadas

```
flake.nix
  └── profiles/{gpu-profile}/default.nix        ← GPU drivers (existente, preservado)
        ├── hosts/{hostname}/                     ← hardware + variables (existente)
        ├── modules/drivers/                      ← GPU drivers (existente)
        └── modules/core/                         ← NixOS base (existente)
              └── user.nix → modules/home/        ← UI ZaneyOS (existente)

NOVO: modules/editions/{edition}/               ← camada de edição
        ├── default.nix                           ← entry point da edição
        ├── dev.nix                               ← ferramentas de desenvolvimento
        ├── homelab.nix                           ← Docker, Portainer, Caddy, DNS
        ├── databases.nix                         ← clientes de banco, DBeaver
        ├── cloud.nix                             ← AWS, GCP, Terraform, K8s
        ├── llm.nix                               ← Ollama opcional, aichat
        └── mobile.nix                            ← Android SDK (full only)

NOVO: modules/home/editions/{edition}/          ← home-manager da edição
        ├── dev-tools.nix                         ← LSPs, NVM wrapper, SDKMAN wrapper
        └── extra-apps.nix                        ← DBeaver GUI, extras visuais

NOVO: docker/stacks/                            ← stacks Docker composáveis
        ├── homelab/
        │   ├── portainer/compose.yml
        │   ├── caddy/compose.yml + Caddyfile
        │   └── ...
        ├── databases/
        │   ├── postgres/compose.yml
        │   ├── mysql/compose.yml
        │   ├── sqlserver/compose.yml
        │   └── adminer/compose.yml
        ├── monitoring/
        │   ├── grafana/compose.yml
        │   └── prometheus/compose.yml
        └── llm/
            └── open-webui/compose.yml
```

### Edição como variável em variables.nix
```nix
# Novo campo em variables.nix
edition = "full";  # "full" | "medium" | "basic" | "vm"
```

---

## 5. Como Adaptar o flake.nix

### Situação atual (problema)
```nix
let
  host = "zaneyos-24-vm";   # hardcoded
  profile = "vm";            # hardcoded
  username = "dwilliams";    # hardcoded
  mkNixosConfig = gpuProfile: ...
```

### Proposta: mkNixosConfig recebe host + username
```nix
let
  mkNixosConfig = { gpuProfile, host, username }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs username host; };
    modules = [
      ./modules/core/overlays.nix
      ./profiles/${gpuProfile}
      nix-flatpak.nixosModules.nix-flatpak
    ];
  };
in {
  nixosConfigurations = {
    # GPU profiles preservados (usam host/user padrão)
    amd            = mkNixosConfig { gpuProfile = "amd";            host = "myhost"; username = "myuser"; };
    nvidia         = mkNixosConfig { gpuProfile = "nvidia";         host = "myhost"; username = "myuser"; };
    nvidia-laptop  = mkNixosConfig { gpuProfile = "nvidia-laptop";  host = "myhost"; username = "myuser"; };
    amd-nvidia-hybrid = mkNixosConfig { gpuProfile = "amd-nvidia-hybrid"; host = "myhost"; username = "myuser"; };
    intel          = mkNixosConfig { gpuProfile = "intel";          host = "myhost"; username = "myuser"; };
    vm             = mkNixosConfig { gpuProfile = "vm";             host = "myhost-vm"; username = "myuser"; };
  };
}
```

### `profile` como variável derivada
O `profile` atual (repassado via specialArgs para scripts como zcli) deve ser lido de `variables.nix`:
```nix
# Em variables.nix do host
edition = "full";
```
E no flake, `profile` pode ser substituído por `edition` nos specialArgs.

---

## 6. Como Adaptar hosts/ Sem Quebrar variables.nix

### Estrutura de host pessoal proposta
```
hosts/
  default/              ← template base (preservado)
  zaneyos-24-vm/        ← host existente (preservado, não versionar HW real)
  zaneyos-oem/          ← host existente (preservado)
  myworkstation/        ← NOVO: seu host de workstation
    default.nix
    hardware.nix        ← gerado por nixos-generate-config (NÃO versionar dados reais)
    host-packages.nix
    variables.nix       ← estende variables.nix base com novos campos
  myvm/                 ← NOVO: host VM para testes
    ...
```

### variables.nix estendida (novos campos a adicionar)
```nix
{
  # === Campos originais ZaneyOS (preservados) ===
  gitUsername = "Seu Nome";
  gitEmail = "seu@email.com";
  displayManager = "tui";
  # ... (todos os originais)

  # === NOVOS campos de edição ===
  edition = "full";          # "full" | "medium" | "basic" | "vm"

  # Timezone e locale (mover de system.nix para variável)
  timeZone = "America/Sao_Paulo";
  locale = "pt_BR.UTF-8";

  # Toggles de homelab
  caddyEnable = true;
  dnsLocalEnable = true;
  portainerEnable = true;

  # Toggles de bancos
  postgresClientEnable = true;
  mysqlClientEnable = true;
  sqlServerClientEnable = false;
  dbeaverEnable = true;

  # Toggles de dev
  nvmEnable = true;
  sdkmanEnable = true;
  miseEnable = true;
  androidSdkEnable = false;

  # Toggles de cloud/devops
  awsCliEnable = true;
  gcpSdkEnable = false;
  terraformEnable = true;
  k8sToolsEnable = false;

  # Toggles de LLM
  ollamaEnable = false;

  # Acesso remoto
  rustdeskEnable = false;
  wayVncEnable = false;
  xrdpEnable = false;
}
```

---

## 7. Novos Módulos por Categoria

### modules/editions/dev.nix
Pacotes de desenvolvimento base (todos os nix packages — NVM/SDKMAN são wrappers shell, não pacotes nix):
- `git`, `lazygit`, `gh`, `delta`, `gitleaks`, `lefthook`, `pre-commit`
- `just`, `direnv`, `mise`
- `zellij` ou `tmux` (já existe em variables.nix)
- `nodejs_22`, `pnpm`, `bun`, `typescript`
- `jdk21`, `maven`, `gradle`
- `python3`, `uv`, `ruff`, `pipx`
- LSPs: `nil`/`nixd`, `typescript-language-server`, `python-lsp-server`, `yaml-language-server`, `bash-language-server`, `biome`, `dockerfile-language-server`
- NVM: instalado via home.sessionVariables + script de inicialização (não é pkg nixpkgs)
- SDKMAN: instalado via home.sessionVariables + script de inicialização (não é pkg nixpkgs)
- `mise`: disponível em nixpkgs como `mise`

### modules/editions/homelab.nix
- `caddy` (serviço NixOS)
- `dnsmasq` (serviço NixOS, bind 127.0.0.1)
- Docker já habilitado em virtualisation.nix
- Portainer: via container Docker (arXiv de compose ou oci-containers)
- Firewall: abrir apenas portas necessárias, sem expor bancos

### modules/editions/databases.nix
- Clientes: `postgresql`, `mysql`, `sqlcmd` (se disponível), `redis`, `pspg`
- DBeaver: `dbeaver-bin` (unfree) — via flag `dbeaverEnable`
- Adminer/CloudBeaver: via Docker compose stacks

### modules/editions/cloud.nix
- `awscli2`, `google-cloud-sdk`, `terraform`, `terragrunt`
- `kubectl`, `k9s`, `helm`, `k3d`, `kubectx`, `stern`, `kustomize`
- `firebase-tools` (via npm ou nixpkgs)

### modules/editions/llm.nix
- `ollama` como serviço NixOS (condicional, `services.ollama.enable`)
- `aichat`, `oterm`
- Open WebUI: via Docker compose

### modules/editions/mobile.nix
- `android-studio` ou `androidSdk` (full only)
- Variáveis de ambiente Android

### modules/home/editions/ (home-manager)
- Configurações de shell para NVM/SDKMAN (sourcing em zsh/fish)
- DBeaver desktop entry
- Integração mise com zsh/fish

---

## 8. Organização dos Stacks Docker

```
docker/
  stacks/
    homelab/
      portainer/
        compose.yml
        .env.example
      caddy/
        compose.yml
        Caddyfile.example
        .env.example
    databases/
      postgres/
        compose.yml
        .env.example       ← POSTGRES_PASSWORD=changeme
      mysql/
        compose.yml
        .env.example
      sqlserver/
        compose.yml
        .env.example
      adminer/
        compose.yml
        .env.example
      cloudbeaver/
        compose.yml
        .env.example
      redis/
        compose.yml
    monitoring/
      grafana/
        compose.yml
        .env.example
      prometheus/
        compose.yml
        prometheus.yml.example
      loki/
        compose.yml
    automation/
      n8n/
        compose.yml
        .env.example
      uptime-kuma/
        compose.yml
      mailpit/
        compose.yml
      homepage/
        compose.yml
        config/
          settings.yaml.example
    storage/
      minio/
        compose.yml
        .env.example
    llm/
      open-webui/
        compose.yml
        .env.example
  README.md              ← instruções de uso dos stacks
```

**Regras dos stacks:**
- Todos os bancos: `127.0.0.1:PORT:PORT` (nunca `0.0.0.0`)
- Caddy faz reverse proxy para os serviços
- Secrets: apenas `.env.example` no repo; `.env` real no `.gitignore`
- Networks internas Docker para isolamento

---

## 9. Matriz de Recursos por Edição

| Recurso | VM | Basic | Medium | Full |
|---|:---:|:---:|:---:|:---:|
| Desktop Hyprland/ZaneyOS | ✅ | ✅ | ✅ | ✅ |
| Stylix/Waybar/Noctalia | ✅ | ✅ | ✅ | ✅ |
| VS Code | ✅ | ✅ | ✅ | ✅ |
| Plymouth boot | ❌ | ✅ | ✅ | ✅ |
| Docker | opt | ✅ | ✅ | ✅ |
| Portainer | opt | ✅ | ✅ | ✅ |
| Caddy | opt | ✅ | ✅ | ✅ |
| DNS local | ❌ | ✅ | ✅ | ✅ |
| PostgreSQL client | ❌ | opt | ✅ | ✅ |
| MySQL client | ❌ | opt | ✅ | ✅ |
| SQL Server client | ❌ | ❌ | ✅ | ✅ |
| Redis client | ❌ | opt | ✅ | ✅ |
| DBeaver | ❌ | ❌ | ✅ | ✅ |
| Adminer (Docker) | opt | ✅ | opt | ❌ |
| CloudBeaver (Docker) | ❌ | ❌ | ✅ | ✅ |
| NVM | ✅ | ✅ | ✅ | ✅ |
| SDKMAN | opt | ✅ | ✅ | ✅ |
| mise | ✅ | ✅ | ✅ | ✅ |
| Node 22 + pnpm + bun | ✅ | ✅ | ✅ | ✅ |
| JDK 21 + Maven + Gradle | opt | ✅ | ✅ | ✅ |
| Python + uv + ruff | ✅ | ✅ | ✅ | ✅ |
| LSPs essenciais | ✅ | ✅ | ✅ | ✅ |
| n8n (Docker) | ❌ | ❌ | ✅ | ✅ |
| Uptime Kuma (Docker) | ❌ | opt | ✅ | ✅ |
| Mailpit (Docker) | ❌ | opt | ✅ | ✅ |
| MinIO (Docker) | ❌ | ❌ | opt | ✅ |
| Grafana + Prometheus | ❌ | ❌ | opt | ✅ |
| Loki | ❌ | ❌ | ❌ | opt |
| AWS CLI | ❌ | ❌ | ✅ | ✅ |
| Google Cloud SDK | ❌ | ❌ | ✅ | ✅ |
| Firebase tools | ❌ | ❌ | ❌ | ✅ |
| Terraform + Terragrunt | ❌ | ❌ | ✅ | ✅ |
| kubectl + k9s + helm | ❌ | ❌ | ✅ | ✅ |
| k3d | ❌ | ❌ | ❌ | ✅ |
| Android SDK | ❌ | ❌ | ❌ | ✅ |
| Ollama (serviço) | ❌ | ❌ | ❌ | opt |
| Open WebUI (Docker) | ❌ | ❌ | ❌ | opt |
| aichat | ❌ | ❌ | opt | ✅ |
| QEMU/libvirt | ❌ | ❌ | ❌ | ✅ |
| RustDesk | ❌ | opt | opt | ✅ |
| WayVNC | opt | opt | opt | opt |
| XRDP/XFCE | opt | ❌ | ❌ | opt |
| SSH (key-only) | ✅ | ✅ | ✅ | ✅ |

Legenda: ✅ = incluído | ❌ = não incluído | opt = opcional/toggle

---

## 10. Matriz de Armazenamento Mínimo

| Edição | Mínimo | Recomendado | Observações |
|---|---|---|---|
| VM | 40 GB | 60 GB | Sem modelos LLM, sem SQL Server |
| Basic | 80 GB | 120 GB | Espaço para Docker volumes |
| Medium | 150 GB | 250 GB | Bancos + imagens Docker |
| Full | 250 GB | 500 GB–1 TB | Modelos LLM + Android SDK + todos os stacks |

---

## 11. Script de Instalação e Documentação

### Análise do install-zaneyos.sh atual

O script atual (`install-zaneyos.sh`) faz o seguinte fluxo:
1. Verifica git, pciutils e NixOS
2. Detecta automaticamente o profile de GPU via `lspci`
3. Pede hostname, git name/email, timezone, keyboard layout
4. Cria `hosts/<hostname>/` copiando de `hosts/default/`
5. Usa `sed` para atualizar `host`, `profile`, `username` em `flake.nix`
6. Atualiza `timezone` em `modules/core/system.nix` via `awk`
7. Atualiza variáveis em `variables.nix` via `awk`
8. Gera `hardware.nix` via `nixos-generate-config`
9. Roda `nixos-rebuild boot --flake ~/zaneyos/#${profile}`

**Problema crítico**: O script clona do repositório ORIGINAL:
```bash
git clone https://gitlab.com/zaney/zaneyos.git -b main --depth=1 ~/zaneyos
```
→ Isso sobrescreve o fork com o original. **Deve ser atualizado para clonar este fork.**

### O Que Precisa Mudar no Script

| Item | Mudança |
|---|---|
| URL do clone | Trocar para URL deste fork (GitHub) |
| Pergunta de `edition` | Adicionar: full / medium / basic / vm |
| `sed` em `flake.nix` | Atualizar padrões para nova estrutura parametrizada |
| `system.nix` | Quando `timezone` virar variável em `variables.nix`, remover patch de `system.nix` |
| `variables.nix` | Adicionar `edition`, `timeZone`, novos toggles ao `awk` de atualização |
| Banner de sucesso | Mencionar fork e edições disponíveis |
| Hardware.nix | Avisar que arquivo gerado é sensível e não deve ser versionado |

### Novo Fluxo do Script Adaptado

```
1. Verificações (git, pciutils, NixOS)  — inalterado
2. Detectar GPU → gpuProfile             — inalterado
3. Pedir hostname                         — inalterado
4. NOVO: Pedir edition (full/medium/basic/vm)
5. Pedir git name/email/timezone/keyboard — inalterado
6. Criar hosts/<hostname>/ do template    — inalterado
7. Atualizar flake.nix (nova estrutura)   — adaptado
8. Atualizar variables.nix (novos campos) — adaptado
9. Gerar hardware.nix                     — inalterado
10. Avisar: hardware.nix não versionar    — NOVO aviso
11. Perguntar se quer rodar rebuild       — inalterado
12. nixos-rebuild boot --flake .#<gpuProfile> — inalterado
```

### Documentação a Criar/Atualizar

#### README.md — Obrigatório
- **Cabeçalho de fork/atribuição** (primeiro item visível):
  ```
  > Este repositório é um fork/adaptação pessoal do ZaneyOS, criado originalmente 
  > por **Tyler Kelley** (Zaney). O projeto original está em: 
  > https://gitlab.com/zaney/zaneyos
  > Este fork adiciona suporte a edições (full/medium/basic/vm), homelab, 
  > ferramentas de desenvolvimento e stacks Docker, preservando integralmente 
  > a interface gráfica do ZaneyOS original.
  ```
- Seção **Edições** com a matriz de recursos
- Seção **Instalação** atualizada (apontar para este fork, não o original)
- Seção **Docker Stacks** — como usar os stacks em `docker/stacks/`
- Seção **Requisitos de armazenamento** por edição

#### Documentos novos a criar
- `docs/editions.md` — Guia detalhado de edições (full/medium/basic/vm)
- `docs/homelab.md` — Guia de configuração do homelab
- `docs/dev-tools.md` — Guia de ferramentas de desenvolvimento (NVM, SDKMAN, mise)
- `docs/docker-stacks.md` — Guia de uso dos stacks Docker
- `docker/stacks/README.md` — Instruções rápidas de cada stack
- `.gitignore` atualizado com:
  ```
  docker/**/.env
  hosts/*/hardware.nix
  !hosts/default/hardware.nix
  *.log
  ```

---

## 12. Sequência de Commits Pequenos

### Fase 0 — Fundação e Documentação (sem alterar UI)
1. `docs(readme): add fork attribution to Tyler Kelley / ZaneyOS original`
2. `chore(gitignore): add rules for .env, hardware.nix, install logs`
3. `feat(flake): parametrize host/username per nixosConfiguration`
4. `feat(hosts): add myhost template with extended variables.nix`
5. `fix(core/services): set SSH to key-only authentication`
6. `fix(core/system): move timezone and locale to variables.nix`
7. `feat(core/boot): disable Plymouth conditionally for vm edition`
8. `fix(install): update clone URL to this fork and add edition prompt`

### Fase 1 — Camada de Edições
6. `feat(editions): create editions module structure`
7. `feat(editions/dev): add base dev tools (git, lazygit, direnv, mise, just)`
8. `feat(editions/dev): add NVM and SDKMAN shell integration`
9. `feat(editions/dev): add Node 22, pnpm, bun, typescript`
10. `feat(editions/dev): add JDK21, maven, gradle`
11. `feat(editions/dev): add Python, uv, ruff, pipx`
12. `feat(editions/dev): add LSPs (nil, ts-ls, python-lsp, yaml, bash, biome)`
13. `feat(editions/dev): add VS Code extensions for dev stack`

### Fase 2 — Homelab
14. `feat(editions/homelab): add Caddy service`
15. `feat(editions/homelab): add local DNS with dnsmasq`
16. `feat(editions/homelab): configure Docker hardening`
17. `feat(editions/homelab): add Portainer via oci-containers or script`
18. `feat(docker/stacks): add database stacks (postgres, mysql, sqlserver)`
19. `feat(docker/stacks): add Adminer stack`
20. `feat(docker/stacks): add CloudBeaver stack`

### Fase 3 — Cloud e DevOps
21. `feat(editions/cloud): add AWS CLI, GCP SDK, Terraform, Terragrunt`
22. `feat(editions/cloud): add kubectl, k9s, helm, k9s, kubectx, stern`
23. `feat(editions/cloud): add k3d (full only)`

### Fase 4 — Monitoring e Automação
24. `feat(docker/stacks): add n8n stack`
25. `feat(docker/stacks): add Uptime Kuma stack`
26. `feat(docker/stacks): add Mailpit stack`
27. `feat(docker/stacks): add Grafana + Prometheus stack`
28. `feat(docker/stacks): add Loki optional stack`
29. `feat(docker/stacks): add MinIO stack`
30. `feat(docker/stacks): add Homepage stack`

### Fase 5 — LLM e Mobile
31. `feat(editions/llm): add Ollama optional service`
32. `feat(docker/stacks): add Open WebUI stack`
33. `feat(editions/llm): add aichat and oterm`
34. `feat(editions/mobile): add Android SDK (full only)`

### Fase 6 — Acesso Remoto, Hardening e Documentação
35. `feat(editions/remote): add RustDesk optional`
36. `feat(editions/remote): add WayVNC optional`
37. `feat(core/security): harden SSH and firewall per edition`
38. `docs: add docs/editions.md with full feature matrix`
39. `docs: add docs/homelab.md with homelab setup guide`
40. `docs: add docs/dev-tools.md with NVM/SDKMAN/mise coexistence guide`
41. `docs: add docs/docker-stacks.md and docker/stacks/README.md`
42. `docs(readme): update installation section for this fork`
43. `docs(readme): add storage requirements and edition selection guide`

---

## 12. Critérios de Aceite

- [ ] `nix flake check` passa sem erros
- [ ] Perfis GPU originais (amd/nvidia/etc.) ainda compilam
- [ ] Desktop Hyprland com Stylix, Waybar/Noctalia, Rofi, SwayNC intactos
- [ ] `variables.nix` backwards-compatible (hosts existentes não quebram)
- [ ] SSH: `PasswordAuthentication = no` + `PermitRootLogin = no`
- [ ] Nenhum banco exposto em `0.0.0.0`
- [ ] `.env` não versionado, apenas `.env.example`
- [ ] `hardware.nix` real não versionado (apenas template)
- [ ] VS Code disponível via `vscodeEnable = true`
- [ ] NVM/SDKMAN: inicializados no shell sem conflito com mise
- [ ] Edição VM: Plymouth desabilitado, sem serviços pesados
- [ ] Edição Full: Ollama opcional (não inicia por padrão, sem baixar modelos)

---

## 13. Comandos de Validação

```bash
# Verificar estrutura do flake sem construir
nix flake check --dry-run

# Mostrar atributos disponíveis
nix flake show

# Build sem aplicar (dry-run por host)
nixos-rebuild dry-build --flake .#amd
nixos-rebuild dry-build --flake .#vm

# Formatar arquivos Nix
nix fmt

# Verificar sintaxe de um arquivo Nix específico
nix eval --file modules/editions/dev.nix --apply builtins.typeOf

# Verificar que .env não está no git
git ls-files docker/ | grep '\.env$'  # deve retornar vazio

# Verificar SSH config após rebuild
grep -E 'PasswordAuthentication|PermitRootLogin' /etc/ssh/sshd_config

# Verificar que bancos estão em 127.0.0.1
docker ps --format '{{.Ports}}' | grep -v '127.0.0.1' | grep -E '5432|3306|1433'
```

---

## 14. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| `host` hardcoded em flake.nix quebra módulos que leem `hosts/${host}/variables.nix` | Alta | Alto | Testar `dry-run` antes de qualquer rebuild |
| NVM/SDKMAN conflitando com mise para versões Node/Java | Média | Médio | Documentar prioridade: mise global, NVM/SDKMAN por projeto |
| `dbeaver-bin` unfree não disponível em nixpkgs canal | Baixa | Médio | Verificar disponibilidade; fallback para flatpak |
| `sqlcmd` não disponível no nixpkgs unstable | Média | Baixo | Usar `usql` ou `mssql-cli` como alternativa; ou via Docker |
| `firebase-tools` sem pacote nix oficial | Alta | Baixo | Instalar via npm global ou home.packages com buildNpmPackage |
| Plymouth + systemd-boot conflito em VM | Baixa | Alto | Plymouth condicional por edição desde o início |
| Portainer via oci-containers vs compose — manutenibilidade | Média | Baixo | Usar `virtualisation.oci-containers` para Portainer |
| Ollama baixando modelos automaticamente | Baixa | Médio | `services.ollama.loadModels = []` — nenhum modelo por padrão |
| Bancos expostos na rede acidentalmente | Baixa | Alto | Todos os compose com `127.0.0.1:PORT:PORT` + firewall |
| hardware.nix real versionado acidentalmente | Média | Médio | `.gitignore` para `hosts/*/hardware.nix` exceto template |

---

## 15. Itens que Precisam de Confirmação Humana

1. **Nome do host principal e username** — qual será o `host` e `username` da workstation real?
2. **Timezone e locale** — `America/Sao_Paulo` + `pt_BR.UTF-8`? Ou outro?
3. **GPU da workstation real** — qual profile GPU usar (amd/nvidia/intel/hybrid)?
4. **`edition` padrão no flake** — qual edição ativar por padrão no nixosConfiguration principal?
5. **Browser padrão** — manter `brave` ou trocar para outro?
6. **`barChoice` padrão** — `noctalia` ou `waybar`? Se waybar, qual tema?
7. **`displayManager` padrão** — `tui` (ly) ou `sddm`?
8. **Portainer** — preferir `virtualisation.oci-containers` (declarativo Nix) ou script manual `docker run`?
9. **DNS local** — `dnsmasq` simples ou `NetworkManager` com plugin dnsmasq? (NM é mais integrado ao ZaneyOS)
10. **SQL Server client** — usar `sqlcmd` (se disponível em nixpkgs) ou `usql` multi-banco ou acesso só via Adminer/CloudBeaver Docker?
11. **Firebase tools** — instalar via npm global no shell ou tentar empacotar via Nix?
12. **Hardware.nix** — versionar um `hardware.nix` template genérico ou deixar completamente fora do repo?
13. **Acesso remoto padrão** — RustDesk habilitado por padrão no Full ou apenas opcional?
14. **`stateVersion`** — manter `23.11` (valor atual do ZaneyOS) ou atualizar?
15. **Wallpaper padrão** — manter `Rainnight.jpg` ou escolher outro para seu host?
