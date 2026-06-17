# VSCode: Keychain Fix & Settings Persistence

## Problema 1: Keychain/Sync não funciona

**Causa**: VSCode não conseguia acessar o gnome-keyring para armazenar credenciais (Sync, tokens GitHub, etc.)

**Solução aplicada** (`modules/home/editors/vscode.nix`):

```nix
# 1. Adicionado libsecret e seahorse aos systemPackages
environment.systemPackages = with pkgs; [
  libsecret
  seahorse
];

# 2. Configurado VSCode para usar secretStorage.keytar (libsecret/gnome-keyring)
userSettings = lib.mkDefault {
  "credentialsProvider" = "secretStorage.keytar";
  "secretStorage.keytar" = true;
};

# 3. No NixOS core (modules/core/security.nix), já habilitado:
security.pam.services.login.enableGnomeKeyring = true;
programs.seahorse.enable = true;
```

**Verificação**:
```bash
# Testar se gnome-keyring está rodando
gnome-keyring-daemon --start --components=secrets

# Verificar se VSCode detecta
code --verbose 2>&1 | grep -i keyring
```

## Problema 2: Settings.json read-only (perde alterações no rebuild)

**Causa**: `lib.mkForce` tornava as configurações imutáveis; Home Manager sobrescreve no rebuild.

**Solução aplicada**:

```nix
# ANTES (imutável):
userSettings = lib.mkForce { ... };

# DEPOIS (base mutável):
baseSettings = { ... };
userSettings = lib.mkDefault baseSettings;
```

**Como funciona agora**:
1. **Configurações base** (Nix): Definidas em `baseSettings` no módulo
2. **Configurações do usuário** (UI): Salvam em `~/.config/Code/User/settings.json`
3. **Merge automático**: VSCode mescla as duas fontes; usuário vence (última escrita)

**Estrutura final**:
```
~/.config/Code/User/
├── settings.json          # Suas alterações via UI (NÃO gerenciado pelo Nix)
├── keybindings.json       # Seus atalhos (NÃO gerenciado)
└── snippets/              # Seus snippets
```

**No rebuild**:
- Home Manager NÃO toca em `settings.json` (force = false)
- Suas preferências persistem
- Novas configurações base do Nix ficam disponíveis como defaults

## Adicionar novas configurações base

Edite `modules/home/editors/vscode.nix`:

```nix
baseSettings = {
  # Suas configurações base aqui
  "workbench.colorTheme" = "Nero Hyprland";
  "editor.formatOnSave" = true;
  # Nova configuração:
  "editor.tabSize" = 2;
};
```

## Troubleshooting

### Keychain ainda não funciona
```bash
# 1. Verificar se gnome-keyring está ativo na sessão
echo $GNOME_KEYRING_CONTROL
echo $SSH_AUTH_SOCK

# 2. Reiniciar daemon
gnome-keyring-daemon --replace --daemonize --components=secrets

# 3. Verificar se libsecret está instalado
nix-shell -p libsecret --run "secret-tool --version"
```

### Settings não persistem
```bash
# Verificar se settings.json NÃO é symlink do Nix
ls -la ~/.config/Code/User/settings.json
# Deve ser arquivo regular, NÃO link para /nix/store

# Se for link, remover e deixar VSCode recriar:
mv ~/.config/Code/User/settings.json ~/.config/Code/User/settings.json.bak
# Abrir VSCode, fazer uma alteração, fechar
```

### Extensões não instalam
```bash
# Verificar se vscode-extensions está disponível
nix search nixpkgs vscode-extensions

# Para extensões do Marketplace não no Open VSX:
# Adicionar em extOrMarketplace com version e sha256
```

## Referências

- [VSCode Secret Storage](https://code.visualstudio.com/docs/editor/settings-sync#_secret-storage)
- [Home Manager VSCode Module](https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix)
- [libsecret on NixOS](https://wiki.nixos.org/wiki/Libsecret)