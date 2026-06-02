# Copilot Instructions for ZaneyOS

## What This Repo Is

A NixOS flake configuration using Home Manager. It is designed to be reproducible across multiple hosts and GPU profiles. Everything is declarative — no manual system mutation.

## Build & Rebuild Commands

```bash
# Rebuild the system (most common workflow)
zcli rebuild

# Update flake inputs + rebuild
zcli update

# Preview changes without applying
zcli rebuild --dry

# Rebuild with confirmation prompts
zcli rebuild --ask

# Rebuild targeting next boot only (safer for major changes)
zcli rebuild-boot

# Format Nix files
nix fmt

# Manual rebuild (specify the profile: amd, nvidia, nvidia-laptop, amd-nvidia-hybrid, intel, vm)
sudo nixos-rebuild switch --flake .#<profile>
```

> Shell scripts must be formatted with `shfmt`. Commits follow [Conventional Commits](https://www.conventionalcommits.org/).

## Architecture Overview

The configuration flows like this:

```
flake.nix
  └── profiles/{gpu-type}/default.nix   ← selects GPU drivers
        ├── hosts/{hostname}/            ← hardware.nix + host-packages.nix
        ├── modules/drivers/             ← GPU driver modules
        └── modules/core/               ← NixOS system config
              └── user.nix              ← imports modules/home via Home Manager
                    └── modules/home/   ← user-level dotfiles/apps
```

**Key variables pass** via `specialArgs` in `flake.nix`: `inputs`, `username`, `host`, `profile`.

## The `variables.nix` Pattern (Critical)

`hosts/{hostname}/variables.nix` is the **single configuration file end-users edit**. Every module that needs host-specific values imports it directly:

```nix
# Pattern used throughout the codebase:
vars = import ../../hosts/${host}/variables.nix;
inherit (vars) barChoice stylixImage animChoice waybarChoice;
```

**Never hardcode host-specific values in modules.** All toggles, choices, and paths belong in `variables.nix`.

## Adding a New Host

```bash
zcli add-host <hostname> <profile>
# or manually:
cp -r hosts/default hosts/<hostname>
# Then edit hosts/<hostname>/variables.nix
# Generate hardware config:
nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware.nix
```

## Key Toggles in `variables.nix`

| Variable | Effect |
|---|---|
| `barChoice = "noctalia"` | Uses Noctalia shell; `"waybar"` uses `waybarChoice` path |
| `displayManager = "tui"` | Uses `ly.nix` TUI login; `"sddm"` uses graphical SDDM |
| `stylixImage` | Drives the **entire** color palette via Stylix (path to wallpaper) |
| `animChoice` | Path to one of the `modules/home/hyprland/animations-*.nix` files |
| `waybarChoice` | Path to one of the `modules/home/waybar/waybar-*.nix` files |
| `*Enable` booleans | Feature flags for terminals, editors, and optional tools |

## Theming (Stylix)

The wallpaper set in `stylixImage` generates all colors system-wide via Stylix. To change the theme, change the wallpaper — do not manually override colors unless using `base16Scheme` in `modules/core/stylix.nix`.

## Conditional Module Imports

Modules are conditionally imported using the `++ (if condition then [...] else [])` pattern in `modules/home/default.nix` and `modules/core/default.nix`. Use this pattern when adding optional modules gated by a `variables.nix` flag.

## Custom Scripts (`modules/home/scripts/`)

Scripts are written with `pkgs.writeShellScriptBin` and exposed via `home.packages`. Each script is its own `.nix` file imported from `scripts/default.nix`. Pass only what the script needs (e.g., `{inherit pkgs;}` or `{inherit pkgs inputs username;}`).

## GPU Profiles (`profiles/`)

Each profile sets driver enable flags:

```nix
drivers.amdgpu.enable = true;
drivers.nvidia.enable = false;
```

The driver modules live in `modules/drivers/`. To add a new GPU profile, create `profiles/<name>/default.nix` following the existing pattern, then add it to the `nixosConfigurations` attrset in `flake.nix`.

## Flake Inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-unstable channel |
| `home-manager` | User environment management |
| `stylix` | System-wide theming from wallpaper |
| `nix-flatpak` | Declarative Flatpak management |
| `nixvim` | Neovim configured via Nix |
| `noctalia` | Alternative shell/bar |
| `alejandra` | Nix formatter (used by `nix fmt`) |
| `awww` | Animated wallpaper support |

## `zcli` Tool

The `zcli` script (defined in `modules/home/scripts/zcli.nix`) is the primary maintenance CLI. Key commands:

- `zcli rebuild` / `zcli update` — rebuild system
- `zcli cleanup` — remove old generations
- `zcli list-gens` — show generations
- `zcli update-host` — update hostname/profile in `flake.nix`
- `zcli doom install|update|remove|status` — manage Doom Emacs
- `zcli diag` — generate diagnostic report to `~/diag.txt`
