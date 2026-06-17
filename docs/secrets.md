# Secrets — Gerenciamento de Segredos

Este guia explica como o ZaneyOS gerencia segredos (senhas de banco, tokens, etc.)
usando o comando **`zstack`** com **age** para criptografia.

---

## Conceitos

| Termo | Significado |
|---|---|
| **age** | Formato de criptografia moderno (chave única, sem complicação) |
| **zstack** | Gerenciador de Docker Stacks e Secrets (bash script) |
| **.env** | Arquivo com senhas para cada stack Docker |
| **.env.age** | Versão criptografada do `.env` (pode ser commitado com segurança) |

> **Nota:** O sistema antigo baseado em sops-nix / `secrets.yaml` / `secrets.enable`
> / `docker.stacks.generateEnvFiles` foi removido. O gerenciamento de segredos
> agora é 100% via `zstack` (scripts bash), sem integração NixOS.

---

## Fluxo de trabalho

```
┌─────────────────────────────────────────────────────────────────┐
│  1. zstack init                                                  │
│     → lê .env.example de cada stack                              │
│     → gera senhas aleatórias                                     │
│     → cria .env files                                            │
├─────────────────────────────────────────────────────────────────┤
│  2. zstack encrypt (opcional)                                    │
│     → criptografa .env → .env.age com age                       │
│     → .env.age pode ser commitado                                │
├─────────────────────────────────────────────────────────────────┤
│  3. zstack up databases                                         │
│     → Docker stacks leem os .env files                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Comando `zstack`

### Gerar .env files com senhas aleatórias

```bash
# Gerar todos os .env (pula os que já existem)
zstack init

# Regenerar tudo (sobrescreve existentes)
zstack init --force

# Gerar apenas uma categoria
zstack init databases
```

O `zstack init` lê o `.env.example` de cada stack, gera senhas fortes usando
`openssl rand`, e cria o `.env` com permissões `0600`. Campos `manual`
(p.ex. OAuth tokens) são solicitados interativamente.

### Criptografar com age (opcional mas recomendado)

```bash
# Criptografar todos os .env
zstack encrypt

# Criptografar uma stack específica
zstack encrypt databases/postgres
```

A age key é gerada automaticamente em `~/zaneyos/.age/key.txt` (com `0600`).
O arquivo `.env.age` pode ser commitado com segurança.

### Descriptografando

```bash
zstack decrypt
zstack decrypt databases/postgres
```

### Troubleshooting

```bash
# Verificar se age está instalado
command -v age

# Verificar se a age key existe
ls -la ~/zaneyos/.age/key.txt

# Testar decrypt manual
age --decrypt -i ~/zaneyos/.age/key.txt docker/stacks/databases/postgres/.env.age

# Regenerar senhas
zstack init --force
```
