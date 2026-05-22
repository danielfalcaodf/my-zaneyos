# Guia de Ferramentas de Desenvolvimento

Este guia explica como as ferramentas de versionamento (`mise`, `NVM`, `SDKMAN`)
coexistem e como instalar ferramentas pós-rebuild.

---

## Estratégia de coexistência

```
Prioridade de versão (crescente — maior prioridade vence):

  mise (global)  <  NVM (por projeto)  <  SDKMAN (por projeto)  <  env explícito
```

| Ferramenta | Gerencia | Escopo | Instalação |
|---|---|---|---|
| `mise` | Node, Python, Go, Ruby, etc. | Global (fallback) | Via Nix (já instalado) |
| `NVM` | Node.js especificamente | Por projeto (`.nvmrc`) | Manual pós-install |
| `SDKMAN` | Java, Kotlin, Scala, Maven, Gradle | Por projeto (`.sdkmanrc`) | Manual pós-install |

**Regra geral:**
- Use `mise` para definir versões globais (`~/.config/mise/config.toml`)
- Use `NVM` em projetos que precisam de versão específica de Node (via `.nvmrc`)
- Use `SDKMAN` em projetos JVM que precisam de JDK específico (via `.sdkmanrc`)

---

## mise (já instalado via Nix)

O `mise` é instalado automaticamente em todas as edições. Funciona como versão global padrão.

```bash
# Verificar instalação
mise --version

# Instalar versão global de Node
mise use --global node@22

# Instalar versão global de Python
mise use --global python@3.12

# Ver versões ativas
mise current

# Listar plugins disponíveis
mise plugins list-all
```

Arquivo de configuração global: `~/.config/mise/config.toml`

### mise em projetos

Crie um arquivo `.mise.toml` ou `.tool-versions` na raiz do projeto:

```toml
# .mise.toml
[tools]
node = "20"
python = "3.11"
```

---

## NVM — instalação manual (primeiro uso)

O NVM não é um pacote Nix — é instalado como script no `~/.nvm`.

```bash
# Instalar NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Reiniciar o shell ou executar:
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

# Verificar instalação
nvm --version

# Instalar Node.js
nvm install 20
nvm install 22
nvm use 22

# Definir padrão global
nvm alias default 22
```

### NVM por projeto

Crie um `.nvmrc` na raiz do projeto:

```
22
```

Em seguida, ao entrar no projeto:

```bash
nvm use  # usa a versão do .nvmrc
```

### NVM no fish shell

O NVM não tem suporte nativo ao fish. Use o plugin `nvm.fish`:

```bash
fisher install jorgebucaran/nvm.fish
```

Ou use `bass` para compatibilidade POSIX:

```bash
fisher install edc/bass
# Então: bass source "$NVM_DIR/nvm.sh"
```

---

## SDKMAN — instalação manual (primeiro uso)

O SDKMAN gerencia versões Java/JVM e também não é um pacote Nix.

```bash
# Instalar SDKMAN
curl -s "https://get.sdkman.io" | bash

# Reiniciar o shell ou executar:
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Verificar instalação
sdk version

# Listar versões disponíveis de Java
sdk list java

# Instalar JDK (ex: Temurin 21)
sdk install java 21.0.3-tem

# Instalar outras ferramentas JVM
sdk install maven
sdk install gradle
sdk install kotlin
```

### SDKMAN por projeto

Crie um `.sdkmanrc` na raiz do projeto:

```
java=21.0.3-tem
maven=3.9.6
```

Ao entrar no projeto:

```bash
sdk env  # ativa versões do .sdkmanrc
```

### SDKMAN no fish shell

O SDKMAN não suporta fish nativamente. Para usar `sdk` no fish, instale `bass`:

```bash
fisher install edc/bass
# Adicione ao ~/.config/fish/config.fish:
# bass source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

---

## Ferramentas já disponíveis via Nix (edições basic+)

Essas ferramentas estão no `PATH` sem instalação adicional:

| Ferramenta | Edição | Uso |
|---|---|---|
| `node` (Node.js 22) | basic+ | Runtime JS global |
| `pnpm` | basic+ | Package manager Node |
| `python3` | basic+ | Runtime Python |
| `uv` | basic+ | Gerenciador Python moderno |
| `ruff` | basic+ | Linter/formatter Python |
| `jdk21` | medium+ | Java Development Kit |
| `maven` | medium+ | Build Java |
| `gradle` | medium+ | Build Java/Kotlin |
| `mise` | basic+ | Versão global de runtimes |

---

## Solução de conflitos

### `node` não encontrado após instalar NVM

O NVM sobrescreve o `node` do PATH. Reinicie o terminal.
Se persistir, verifique a ordem de inicialização no `~/.zshrc` — NVM deve vir **depois** do `mise`.

### Java do SDKMAN conflita com JDK do Nix

O SDKMAN adiciona o Java selecionado no início do PATH. Para volcar ao JDK Nix:

```bash
sdk flush
sdk env clear  # fora de projetos com .sdkmanrc
```

### mise não ativa versão do projeto

```bash
cd /caminho/do/projeto
mise trust    # autorizar o .mise.toml do projeto
mise current  # verificar versões ativas
```
