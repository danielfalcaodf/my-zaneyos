[English](README.md) | [Español](README.es.md)

<div align="center">

## ZaneyOS — Personal Fork / Adaptação Pessoal ❄️

> **Fork/adaptação pessoal** do [ZaneyOS](https://gitlab.com/zaney/zaneyos), criado originalmente por **Tyler Kelley (Zaney)**.
> Este fork preserva integralmente a interface gráfica do ZaneyOS original e adiciona uma camada de
> **edições** (full / medium / basic / vm), ferramentas de desenvolvimento, homelab e stacks Docker.
> Todo crédito pela estética, identidade visual e estrutura base pertence ao projeto original.

\*\* Base: ZaneyOS | Fork atualizado: 2026

ZaneyOS is a simple way of reproducing my configuration on any NixOS system.
This includes the wallpaper, scripts, applications, config files, and more.

## Important Note on Noctalia

> The first time you login, screen will be blank SUPER + SHIFT + C to exit.
> Login in, noctalia will start from then on

<img align="center" width="80%" src="img/ZaneyOS-Floating.png" />

</div>

<details>
<summary><strong>📸 More Screenshots</strong></summary>

### Waybar Themes

<img align="center" width="80%" src="img/demo-img2.png" />

<img align="center" width="80%" src="img/demo-img3.png" />

### Noctalia Shell Integration

<img align="center" width="80%" src="img/ZaneyOS-noctalia-panel.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-app.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-settings.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-weather.png" />

### Additional Features

<img align="center" width="80%" src="img/ZaneyOS-keybind-search.png" />

<img align="center" width="80%" src="img/ZaneyOS-nivim-emacs.png" />

</details>

<div align="center">

### Fork Docs

- [Installation Guide](docs/installation.md) — automated + manual install, post-install steps
- [Editions Guide](docs/editions.md) — vm / basic / medium / full feature matrix
- [Homelab Guide](docs/homelab.md) — Caddy, DNS local, Portainer, Homepage, Woodpecker CI
- [Dev Tools Guide](docs/dev-tools.md) — NVM / SDKMAN / mise coexistence
- [Docker Stacks Reference](docs/docker-stacks.md) — all available stacks + `zstack` manager
- [AI Tools Guide](docs/ai-tools.md) — AI coding tools by edition
- [Woodpecker CI Guide](docs/woodpecker-ci.md) — self-hosted CI/CD with Docker
- [Discord + Claude Workflow](docs/automation/discord-claude-workflow.md) — Claude Code Channels via Discord
- [Akita-style AI Workflow](docs/automation/akita-style-ai-workflow.md) — safe pair programming with AI

### Cheatsheets and Guides

- Nix Beginner Guide: [English](cheatsheets/nix-beginner-guide.md) |
  [Español](cheatsheets/nix-beginner-guide.es.md)
- Hyprland Customization Guide:
  [English](cheatsheets/hyprland-customization-guide.md) |
  [Español](cheatsheets/hyprland-customization-guide.es.md)

#### 🍖 Requirements

- You must be running on NixOS, version 24.05+.
- The `zaneyos` folder (this repo) is expected to be in your home directory.
- You must have installed NIXOS using **GPT** parition with booting with
  **UEFI**.
- ** 500MB minimum /boot partition required. **
- Systemd-boot is what is supported.
- For GRUB you will have to brave the internet for a how-to. ☺️
- Manually editing your host specific files.
- The host is the specific computer your installing on.

#### 🎹 Pipewire & Notification Menu Controls

- We are using the latest and greatest audio solution for Linux. Not to mention
  you will have media and volume controls in the notification center available
  in the top bar.

#### 🏇 Optimized Workflow & Simple Yet Elegant Neovim

- Using Hyprland for increased elegance, functionality, and efficiency.
- No massive NeoVIM project here, using `nixvim` for an
  incredible NeoVIM setup. With language support already added in.

#### 🖥️ Multi Host & User Configuration

- You can define separate settings for different host machines and users.
- Easily specify extra packages for your users in the `modules/core/user.nix`
  file.
- Easy to understand file structure and simple, but encompassing, configuration.

#### 👼 An Incredible Community Focused On Support

- The entire idea of ZaneyOS is to make NixOS an approachable space.
- NixOS is actually a great community that you will want to be a part of.
- Many people who are patient and happy to spend their free time helping you are
  running ZaneyOS.
- Feel free to reach out on the Discord for any help with anything.

#### 📦 How To Install Packages?

- You can search the [Nix Packages](https://search.nixos.org/packages?) &
  [Options](https://search.nixos.org/options?) pages for what a package may be
  named or if it has options available that take care of configuration hurdles
  you may face.
- To add a package there are the sections for it in `modules/core/packages.nix`
  and `modules/core/user.nix`. One is for programs available system wide and the
  other for your users environment only.

#### 🙋 Having Issues / Questions?

- Please feel free to raise an issue on the repo, please label a feature request
  with the title beginning with [feature request], thank you!
- Contact us on [Discord](https://discord.gg/XhZmNTnhtp) as well, for a potentially
  faster response.

## Editions

This fork adds an **edition** layer on top of ZaneyOS. Set `edition` in `hosts/<hostname>/variables.nix`.

| Edition | Use case |
|---|---|
| `vm` | Virtual machines, lightweight test environments |
| `basic` | Development desktop + basic homelab (Caddy, DNS, Docker) |
| `medium` | Full workstation: cloud tools, databases, kubernetes CLI |
| `full` | Maximum: LLM (Ollama optional), Android SDK, all stacks |

Each edition is **additive** — `full` includes everything from `medium`, which includes `basic`.

### Storage requirements by edition

| Edition | Minimum | Recommended |
|---|---|---|
| `vm` | 40 GB | 60 GB |
| `basic` | 80 GB | 120 GB |
| `medium` | 150 GB | 250 GB |
| `full` | 250 GB | 500 GB–1 TB |

See [docs/editions.md](docs/editions.md) for the full feature matrix.

---

# Hyprland Keybindings

Below are the keybindings for Hyprland, formatted for easy reference. The right
column shows keybindings that are specific to **Noctalia Shell** (only available
when `barChoice = "noctalia"`).

<table>
<tr>
<td width="50%">

## Standard Keybindings

### Application Launching

- `$modifier + Return` → Launch `terminal`
- `$modifier + Tab` → Toggle `Quickshell Overview` (workspace overview with live previews)
- `$modifier + K` → List keybinds
- `$modifier + Shift + W` → Open `web-search`
- `$modifier + Alt + W` → Open `wallsetter`
- `$modifier + Shift + N` → Run `swaync-client -rs`
- `$modifier + W` → Launch `Web Browser`
- `$modifier + Y` → Open `kitty` with `yazi`
- `$modifier + E` → Open `emopicker9000`
- `$modifier + S` → Take a screenshot
- `$modifier + Shift + D` → Open `Discord`
- `$modifier + O` → Launch `OBS Studio`
- `$modifier + Alt + C` → Color Picker
- `$modifier + G` → Open `GIMP`
- `$modifier + T` → Toggle terminal with `pypr`
- `$modifier + Alt + M` → Open `pavucontrol`

### Window Management

- `$modifier + Q` → Kill active window
- `$modifier + P` → Toggle pseudo tiling
- `$modifier + Shift + I` → Toggle split mode
- `$modifier + F` → Toggle fullscreen
- `$modifier + Shift + F` → Toggle floating mode
- `$modifier + Alt + F` → Float all windows
- `$modifier + Shift + C` → Exit Hyprland

### Window Movement

- `$modifier + Shift + ← / → / ↑ / ↓` → Move left/right/up/down
- `$modifier + Shift + H / L / K / J` → Move left/right/up/down
- `$modifier + Alt + ← / → / ↑ / ↓` → Swap left/right/up/down

### Focus Movement

- `$modifier + ← / → / ↑ / ↓` → Move focus left/right/up/down
- `$modifier + H / L / K / J` → Move focus left/right/up/down

### Workspaces

- `$modifier + 1-10` → Switch to workspace 1-10
- `$modifier + Shift + Space` → Move window to special workspace
- `$modifier + Space` → Toggle special workspace
- `$modifier + Shift + 1-10` → Move window to workspace 1-10
- `$modifier + Control + → / ←` → Switch workspace forward/backward

### Window Cycling

- `Alt + Tab` → Cycle to next window / Bring active to top

</td>
<td width="50%">

## 🎨 Noctalia Shell Keybindings

_Available when `barChoice = "noctalia"` in `variables.nix`_

- `$modifier + D` → Launcher Toggle
- `$modifier + Shift + Return` → Launcher Toggle
- `$modifier + M` → Notifications Menu
- `$modifier + V` → Clipboard Manager
- `$modifier + Alt + P` → Settings Panel
- `$modifier + Shift + ,` → Settings Panel
- `$modifier + Alt + L` → Lock Screen
- `$modifier + Shift + Y` → Wallpaper Manager
- `$modifier + X` → Power Menu
- `$modifier + C` → Control Center
- `$modifier + Ctrl + R` → Screen Recorder

### Rofi Launcher (Waybar Mode)

_Available when `barChoice = "waybar"` in `variables.nix`_

- `$modifier + D` → Launch Rofi Launcher
- `$modifier + Shift + Return` → Launch Rofi Launcher

### Other Features

- `$modifier + Shift + Return` (Waybar) → Application Launcher
- `$modifier + V` (Waybar) → Clipboard History via `cliphist`

</td>
</tr>
</table>

## Installation

> **⚠️ NEW INSTALLATIONS ONLY.** This installs this fork — not the original ZaneyOS.

For the complete guide (pre-requisites, edition selection, post-install, troubleshooting)
see **[docs/installation.md](docs/installation.md)**.

### Quick install (automated)

```bash
# 1. Enter shell with dependencies
nix-shell -p git curl pciutils

# 2. Run this fork's install script
sh <(curl -L https://raw.githubusercontent.com/danielfalcaodf/my-zaneyos/main/install-zaneyos.sh)

# 3. Reboot after the script completes
reboot
```

The script will ask for hostname, edition (`vm`/`basic`/`medium`/`full`), timezone, and GPU profile.

### Manual install

```bash
nix-shell -p git vim
cd ~ && git clone https://github.com/danielfalcaodf/my-zaneyos.git -b main --depth=1 ~/zaneyos
cd ~/zaneyos
cp -r hosts/default hosts/<your-hostname>
# Edit hosts/<your-hostname>/variables.nix
nixos-generate-config --show-hardware-config > hosts/<your-hostname>/hardware.nix
NIX_CONFIG="experimental-features = nix-command flakes"
sudo nixos-rebuild boot --flake .#<gpu-profile>
reboot
```

GPU profiles: `amd`, `nvidia`, `nvidia-laptop`, `amd-nvidia-hybrid`, `intel`, `vm`

### Special Recognitions

- KoolDots  https://github.com/LinuxBeginnings
- JakKoolit  https://github.com/Jakoolit
- Justaguylinux https://codeberg.org/Justaguylinux
- Jerry Starke https://github.com/JerrySM64
