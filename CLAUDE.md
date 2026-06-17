# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Rebuilding the system

```bash
zcli rebuild              # Rebuild and switch immediately
zcli rebuild-boot         # Rebuild for next boot (safer for major changes)
zcli update               # Update flake inputs + rebuild
zcli rebuild --dry        # Preview changes without applying
zcli rebuild --cores 4    # Limit CPU cores (useful in VMs)
```

### Formatting

```bash
nix fmt                   # Format all .nix files via alejandra
```

### Custom packages

```bash
zcli pkg scaffold <github-url>   # Scaffold a new custom package derivation
zcli pkg list                    # List custom packages in pkgs/
```

### Docker stacks

```bash
zstack list                      # List all stacks
zstack init                      # Initialize .env from .env.example (all stacks)
zstack up <category>             # Start all services in a category
zstack up <category>/<service>   # Start a single service
zstack down / logs / restart     # Same pattern
zstack ps                        # Status of all containers
zstack doctor                    # Diagnose problems
```

### Host management

```bash
zcli add-host <hostname> <profile>   # Create new host from default template
zcli update-host [hostname] [profile] # Update flake.nix host/profile values
zcli cleanup                          # Remove old system generations
```

## Architecture

### Configuration entry point

`flake.nix` defines `nixosConfigurations` for each GPU profile (`amd`, `nvidia`, `nvidia-laptop`, `amd-nvidia-hybrid`, `intel`, `vm`). Each profile lives in `profiles/<name>/default.nix` and wires together:
1. `hosts/<hostname>/` — host-specific config
2. `modules/drivers/` — GPU driver module
3. `modules/core/` — all system-level NixOS modules

### Host customization

All per-machine settings are in `hosts/<hostname>/variables.nix`. This is the **primary file to edit** when customizing a system — it controls edition, display manager, bar choice, monitors, keyboard layout, homelab network, and all optional feature toggles.

To add a new host: copy `hosts/default/` to `hosts/<your-hostname>/`, edit `variables.nix`, generate `hardware.nix` with `nixos-generate-config`, then set `host` in `flake.nix`.

### Edition system (additive feature layers)

The `edition` variable in `variables.nix` selects a feature layer loaded by `modules/core/default.nix`:

| Edition | Adds over previous |
|---|---|
| `vm` | Minimal — Plymouth disabled, no homelab |
| `basic` | Docker, Caddy, local DNS, secrets, PostgreSQL client |
| `medium` | JVM/SDKMAN, cloud tools (AWS/GCP/k8s), databases, AI coding tools |
| `full` | Ollama, k3d, Firebase, aichat, distrobox, Hermes Agent |

- System-level edition modules: `modules/editions/`
- Home Manager edition modules: `modules/home/editions/`

### Module layout

- `modules/core/` — NixOS system modules (services, hardware, boot, secrets, caddy, DNS, docker-registry, etc.)
- `modules/home/` — Home Manager user modules (editors, terminals, hyprland, waybar, scripts, CLI tools)
- `modules/home/scripts/` — Shell scripts exposed as Home Manager packages (`zcli`, `zstack`, etc.)
- `modules/drivers/` — GPU driver abstractions
- `modules/ai-tools/` — AI tool tiers (tier1/2/3) mapped to editions

### Custom packages

`pkgs/default.nix` is an aggregator imported by `modules/core/overlays.nix`. To add a package from GitHub not in nixpkgs: run `zcli pkg scaffold <url>` → add entry to `pkgs/default.nix` → use in `modules/core/packages.nix` or `modules/home/default.nix`.

### Homelab stack

Services run as Docker Compose stacks in `docker/stacks/`. The network topology:
- **Blocky** (NixOS service, port 53) — DNS proxy, resolves `*.homelab.lan` to local IP
- **Caddy** (NixOS service, ports 80/443) — reverse proxy with internal CA (HTTPS for all services)
- Docker stacks provide the actual services (Portainer, Homepage, Grafana, n8n, databases, etc.)

Each stack category has a `compose.yml` root that starts all services, plus standalone `<service>/compose.yml` files. All secrets are in `.env` files copied from `.env.example`.

### Bar/shell choice

`barChoice` in `variables.nix` selects between `"noctalia"` (Quickshell-based) and `"waybar"`. The `waybarChoice` variable selects which waybar theme file to use (many options in `modules/home/waybar/`). Both are managed in `modules/home/default.nix`.

### Secrets

Secrets are managed via `zstack secrets-init` (generates random passwords) and stored in `.env` files per stack. The sops-nix integration has been removed; `modules/core/secrets.nix` is intentionally empty.

### Formatter

`alejandra` is the Nix formatter. It is registered as `formatter.x86_64-linux` in `flake.nix` so `nix fmt` works from the repo root.

## Commit rules

These rules apply to every commit in this repository:

- **No co-authorship metadata** — do not add `Co-Authored-By` trailers
- **No credentials in any file type** — check `.nix`, `.yml`, `.yaml`, `.sh`, `.json` as well as `.env`; placeholders like `changeme` are fine, real secrets are not
- **Never commit `hosts/`** — host configs (`hardware.nix`, `variables.nix`, etc.) are machine-specific and may contain IPs or sensitive settings; they live only on disk, never in git
- **Never commit Docker runtime files** — `docker/stacks/homelab/caddy/Caddyfile`, `homepage/config/`, volume data, and any generated runtime config belong to `.gitignore`, not to commits
- **Always exclude** `.history/` and `.hermes/plans/`

### Why `hosts/` must stay on disk but not in git

`flake.nix` imports `hosts/${host}/` at build time, so `hardware.nix` and `variables.nix` must exist on disk for `zcli rebuild` and `nixos-rebuild` to succeed. If you need to stash other changes, use `git stash --keep-index` or explicitly exclude `hosts/` from the stash to avoid breaking the build. To share a machine template, copy `hosts/default/` and fill it in manually.
