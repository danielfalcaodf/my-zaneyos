#!/usr/bin/env bash

######################################
# Install script for zaneyos
# Author:  Don Williams
# Date: June 27, 2005
#######################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define log file
LOG_DIR="$(dirname "$0")"
LOG_FILE="${LOG_DIR}/install_$(date +"%Y-%m-%d_%H-%M-%S").log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print a section header
print_header() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║ ${1} ${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a configuration summary
# Args: hostname profile edition username timezone kbLayout kbVariant consoleKeyMap localDomain lanIP tailscale
print_summary() {
  echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                 📋 Installation Configuration Summary                 ║${NC}"
  echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║  🖥️  Hostname:        ${BLUE}${1}${NC}"
  echo -e "${CYAN}║  🎮 GPU Profile:      ${BLUE}${2}${NC}"
  echo -e "${CYAN}║  📦 Edition:          ${BLUE}${3}${NC}"
  echo -e "${CYAN}║  👤 System Username:  ${BLUE}${4}${NC}"
  echo -e "${CYAN}║  🌐 Timezone:         ${BLUE}${5}${NC}"
  echo -e "${CYAN}║  ⌨️  Keyboard Layout:  ${BLUE}${6}${NC}"
  echo -e "${CYAN}║  ⌨️  Keyboard Variant: ${BLUE}${7:-none}${NC}"
  echo -e "${CYAN}║  🖥️  Console Keymap:   ${BLUE}${8:-$6}${NC}"
  echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║  🌍 Homelab Domain:   ${BLUE}${9:-homelab.lan}${NC}"
  echo -e "${CYAN}║  📡 LAN IP:           ${BLUE}${10:-127.0.0.1}${NC}"
  echo -e "${CYAN}║  🔒 Tailscale VPN:    ${BLUE}${11:-false}${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print an error message
print_error() {
  echo -e "${RED}Error: ${1}${NC}"
}

# Function to print a success banner
print_success_banner() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║            ZaneyOS Custom — Installation Successful! 🎉               ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}║   After reboot, run: zcli diag    to verify your setup               ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a failure banner
print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║               ZaneyOS Custom — Installation Failed!                   ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║   Please review the log file for details:                             ║${NC}"
  echo -e "${RED}║   ${LOG_FILE}                                                        ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_header "Verifying System Requirements"

# Check for git
if ! command -v git &>/dev/null; then
  print_error "Git is not installed."
  echo -e "Please install git and pciutils are installed, then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

# Check for lspci (pciutils)
if ! command -v lspci &>/dev/null; then
  print_error "pciutils is not installed."
  echo -e "Please install git and pciutils,  then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

if [ -n "$(grep -i nixos </etc/os-release)" ]; then
  echo -e "${GREEN}Verified this is NixOS.${NC}"
else
  print_error "This is not NixOS or the distribution information is not available."
  exit 1
fi

print_header "Initial Setup"

echo -e "Default options are in brackets []"
echo -e "Just press enter to select the default"
sleep 2

print_header "Ensure In Home Directory"
cd "$HOME" || exit 1
echo -e "${GREEN}Current directory: $(pwd)${NC}"

print_header "Hostname Configuration"

# Critical warning about using "default" as hostname
echo -e "${RED}⚠️  IMPORTANT WARNING: Do NOT use 'default' as your hostname!${NC}"
echo -e "${RED}   The 'default' hostname is a template and will be overwritten during updates.${NC}"
echo -e "${RED}   This will cause you to lose your configuration!${NC}"
echo ""
echo -e "💡 Suggested hostnames: my-desktop, gaming-rig, workstation, nixos-laptop"
read -rp "Enter Your New Hostname: [ my-desktop ] " hostName
if [ -z "$hostName" ]; then
  hostName="my-desktop"
fi

# Double-check if user accidentally entered "default"
if [ "$hostName" = "default" ]; then
  echo -e "${RED}❌ Error: You cannot use 'default' as hostname. Please choose a different name.${NC}"
  read -rp "Enter a different hostname: " hostName
  if [ -z "$hostName" ] || [ "$hostName" = "default" ]; then
    echo -e "${RED}Setting hostname to 'my-desktop' to prevent configuration loss.${NC}"
    hostName="my-desktop"
  fi
fi

echo -e "${GREEN}✓ Hostname set to: $hostName${NC}"

print_header "GPU Profile Detection"

# Attempt automatic detection
DETECTED_PROFILE=""

has_nvidia=false
has_intel=false
has_amd=false
has_vm=false
detect_vm() {
  if command -v systemd-detect-virt &>/dev/null; then
    if systemd-detect-virt --quiet; then
      return 0
    fi
  fi
  for f in /sys/class/dmi/id/product_name /sys/class/dmi/id/sys_vendor; do
    if [ -r "$f" ] && grep -Eqi 'qemu|kvm|vmware|virtualbox|hyper-v|microsoft corporation|xen|parallels' "$f"; then
      return 0
    fi
  done
  return 1
}

if detect_vm; then
  has_vm=true
fi

if lspci | grep -qi 'vga\|3d\|display'; then
  while read -r line; do
    if echo "$line" | grep -Eq '\[10de:'; then
      has_nvidia=true
    elif echo "$line" | grep -Eq '\[1002:'; then
      has_amd=true
    elif echo "$line" | grep -Eq '\[8086:'; then
      has_intel=true
    elif echo "$line" | grep -Eq '\[(1af4|15ad|80ee|1b36|1414|1234|1013):'; then
      has_vm=true
    elif echo "$line" | grep -qi 'nvidia'; then
      has_nvidia=true
    elif echo "$line" | grep -qi 'amd\|ati\|advanced micro devices'; then
      has_amd=true
    elif echo "$line" | grep -qi 'intel'; then
      has_intel=true
    elif echo "$line" | grep -Eqi 'virtio|vmware|virtualbox|qxl|hyper-v|microsoft corporation|parallels|qemu|bochs|cirrus|svga|virtual'; then
      has_vm=true
    fi
  done < <(lspci -nn | grep -i 'vga\|3d\|display')

  if $has_vm; then
    DETECTED_PROFILE="vm"
  elif $has_nvidia && $has_amd; then
    DETECTED_PROFILE="amd-nvidia-hybrid"
  elif $has_nvidia && $has_intel; then
    DETECTED_PROFILE="nvidia-laptop"
  elif $has_nvidia; then
    DETECTED_PROFILE="nvidia"
  elif $has_amd; then
    DETECTED_PROFILE="amd"
  elif $has_intel; then
    DETECTED_PROFILE="intel"
  fi
fi

# Handle detected profile or fall back to manual input
if [ -n "$DETECTED_PROFILE" ]; then
  profile="$DETECTED_PROFILE"
  echo -e "${GREEN}Detected GPU profile: $profile${NC}"
  read -p "Correct? (Y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}GPU profile not confirmed. Falling back to manual selection.${NC}"
    profile="" # Clear profile to force manual input
  fi
fi

# If profile is still empty (either not detected or not confirmed), prompt manually
if [ -z "$profile" ]; then
  echo -e "${RED}Automatic GPU detection failed or no specific profile found.${NC}"
  read -rp "Enter Your Hardware Profile (GPU)
Options:
[ amd ]
amd-nvidia-hybrid
intel
nvidia
nvidia-laptop
vm
Please type out your choice: " profile
  if [ -z "$profile" ]; then
    profile="amd"
  fi
  echo -e "${GREEN}Selected GPU profile: $profile${NC}"
fi

print_header "⚠️  CRITICAL WARNING - Existing ZaneyOS Detected"

backupname=$(date +"%Y-%m-%d-%H-%M-%S")
if [ -d "zaneyos" ]; then
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                    ⚠️  IMPORTANT WARNING ⚠️                           ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║  An existing ZaneyOS installation was detected at ~/zaneyos           ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║  This installer will COMPLETELY REPLACE your existing configuration!  ║${NC}"
  echo -e "${RED}║  All customizations, packages, and settings will be LOST!             ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║     ** A backup copy of your config will be created **                ║${NC}"
  echo -e "${RED}║      * You will have to merge your changes back **                    ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}If you REALLY want to do a fresh installation (losing all customizations):${NC}"
  read -p "Type 'REPLACE' to continue with fresh install or Ctrl+C to cancel: " confirmation
  if [ "$confirmation" != "REPLACE" ]; then
    echo -e "${GREEN}Installation cancelled. ${NC}"
    exit 0
  fi
  echo -e "${GREEN}zaneyos exists, backing up to .config/zaneyos-backups folder.${NC}"
  if [ -d ".config/zaneyos-backups" ]; then
    echo -e "${GREEN}Moving current version of ZaneyOS to backups folder.${NC}"
    mv "$HOME"/zaneyos .config/zaneyos-backups/"$backupname"
    sleep 1
  else
    echo -e "${GREEN}Creating the backups folder & moving ZaneyOS to it.${NC}"
    mkdir -p .config/zaneyos-backups
    mv "$HOME"/zaneyos .config/zaneyos-backups/"$backupname"
    sleep 1
  fi
else
  echo -e "${GREEN}Thank you for choosing ZaneyOS.${NC}"
  echo -e "${GREEN}I hope you find your time here enjoyable!${NC}"
fi

print_header "Cloning Repository"
git clone https://github.com/danielfalcaodf/my-zaneyos.git -b feat/devdaniel-homelab-editions --depth=1 ~/zaneyos
cd ~/zaneyos || exit 1

print_header "Git Configuration"
echo "👤 Setting up git configuration for version control:"
echo "  This is needed for system updates and configuration management."
echo ""
installusername=$(echo $USER)
echo -e "Current username: ${GREEN}$installusername${NC}"
read -rp "Enter your full name for git commits [ $installusername ]: " gitUsername
if [ -z "$gitUsername" ]; then
  gitUsername="$installusername"
fi

echo "📧 Examples: john@example.com, jane.doe@company.org"
read -rp "Enter your email address for git commits [ $installusername@example.com ]: " gitEmail
if [ -z "$gitEmail" ]; then
  gitEmail="$installusername@example.com"
fi

echo -e "${GREEN}✓ Git name: $gitUsername${NC}"
echo -e "${GREEN}✓ Git email: $gitEmail${NC}"

print_header "Timezone Configuration"
echo "🌎 Fusos horários comuns:"
echo "  • Brasil: America/Sao_Paulo, America/Fortaleza, America/Manaus, America/Belem"
echo "  • US: America/New_York, America/Chicago, America/Denver, America/Los_Angeles"
echo "  • Europe: Europe/London, Europe/Berlin, Europe/Paris, Europe/Rome"
echo "  • Asia: Asia/Tokyo, Asia/Shanghai, Asia/Seoul, Asia/Kolkata"
echo "  • Australia: Australia/Sydney, Australia/Melbourne"
echo "  • UTC (Universal): UTC"
read -rp "Entre com o fuso horário [ America/Sao_Paulo ]: " timezone
if [ -z "$timezone" ]; then
  timezone="America/Sao_Paulo"
fi
echo -e "${GREEN}✓ Timezone definido: $timezone${NC}"

print_header "Edition Selection"
echo "📦 Choose your system edition:"
echo "  • full   — Complete workstation: dev tools, homelab, Docker stacks, LLM, cloud/k8s"
echo "  • medium — Dev workstation: dev tools, homelab, Docker, cloud tools (no LLM/Android)"
echo "  • basic  — Light desktop: VS Code, Docker, Portainer, Caddy, essential dev tools"
echo "  • vm     — Minimal for VMs: lightweight, no heavy services, no Plymouth"
echo ""
echo "  Storage requirements:"
echo "    vm: min 40GB  | basic: min 80GB  | medium: min 150GB  | full: min 250GB"
echo ""
read -rp "Enter your edition [ basic ]: " edition
if [ -z "$edition" ]; then
  edition="basic"
fi
# Validate edition
case "$edition" in
full | medium | basic | vm) ;;
*)
  echo -e "${YELLOW}⚠️  Unknown edition '$edition'. Defaulting to 'basic'.${NC}"
  edition="basic"
  ;;
esac
echo -e "${GREEN}✓ Edition set to: $edition${NC}"

# Warn when the user picks 'vm' edition on a machine already detected as a VM.
# 'vm' GPU profile (no GPU drivers) ≠ 'vm' edition (minimal software).
# A homelab server running inside a VM should use basic/medium/full edition.
if [ "$edition" = "vm" ] && [ "$profile" = "vm" ]; then
  echo ""
  echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║  ⚠️  ATENÇÃO: GPU profile 'vm' ≠ Edition 'vm'                         ║${NC}"
  echo -e "${YELLOW}║                                                                       ║${NC}"
  echo -e "${YELLOW}║  O GPU profile 'vm' foi detectado automaticamente (sem drivers GPU).  ║${NC}"
  echo -e "${YELLOW}║  A edition 'vm' é MINIMALISTA: sem VS Code, sem Docker, sem Node.     ║${NC}"
  echo -e "${YELLOW}║                                                                       ║${NC}"
  echo -e "${YELLOW}║  Para um servidor homelab rodando como VM, use: basic, medium ou full ║${NC}"
  echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -rp "Manter edição 'vm' (minimal)? Ou digite outra [ basic ]: " edition_override
  if [ -n "$edition_override" ] && [ "$edition_override" != "vm" ]; then
    case "$edition_override" in
    full | medium | basic) edition="$edition_override" ;;
    *) edition="basic" ;;
    esac
    echo -e "${GREEN}✓ Edition alterada para: $edition${NC}"
  fi
fi

print_header "Keyboard Layout Configuration"
echo "🌍 Layouts de teclado comuns:"
echo "  • br (Português Brasil - ABNT2) - padrão"
echo "  • us (US English)"
echo "  • us-intl (US International)"
echo "  • uk (UK English)"
echo "  • de (German)"
echo "  • fr (French)"
echo "  • es (Spanish)"
echo "  • it (Italian)"
echo "  • ru (Russian)"
echo "  • dvorak (Dvorak)"
read -rp "Entre com o layout do teclado: [ br ] " keyboardLayout
if [ -z "$keyboardLayout" ]; then
  keyboardLayout="br"
fi
echo -e "${GREEN}✓ Layout do teclado definido: $keyboardLayout${NC}"

print_header "Keyboard Variant Configuration"
# Suggest a variant when user typed a variant-like layout
variant_suggestion=""
case "$keyboardLayout" in
dvorak | colemak | workman | intl | us-intl)
  variant_suggestion="$keyboardLayout"
  ;;
*) ;;
esac
read -rp "Enter your keyboard variant (e.g., dvorak) [ $variant_suggestion ]: " keyboardVariant
keyboardVariant="${keyboardVariant:-$variant_suggestion}"

# Normalize layout/variant to avoid accidentally forcing US for non-US layouts
# - Accept uppercase inputs; treat BR/DE/FR/ES/IT/RU/UK in variant field as layout
# - Map us-intl/intl and dvorak/colemak/workman to layout=us + appropriate variant
keyboardLayout=$(echo "$keyboardLayout" | tr '[:upper:]' '[:lower:]')
keyboardVariant=$(echo "$keyboardVariant" | tr '[:upper:]' '[:lower:]')

case "$keyboardLayout" in
us-intl | intl)
  keyboardLayout="us"
  if [ -z "$keyboardVariant" ]; then keyboardVariant="intl"; fi
  ;;
dvorak | colemak | workman)
  if [ -z "$keyboardVariant" ]; then keyboardVariant="$keyboardLayout"; fi
  keyboardLayout="us"
  ;;
*) ;;
esac

# If a layout accidentally ended up in the variant field, fix it
if [[ "$keyboardVariant" =~ ^(us|br|de|fr|es|it|ru|uk)$ ]]; then
  keyboardLayout="$keyboardVariant"
  keyboardVariant=""
fi

if [ -z "$keyboardVariant" ]; then
  echo -e "${GREEN}✓ Keyboard variant set to: none${NC}"
else
  echo -e "${GREEN}✓ Keyboard variant set to: $keyboardVariant${NC}"
fi

print_header "Console Keymap Configuration"
echo "⌨️  Keymap do console (normalmente igual ao layout do teclado):"
echo "  Mais comuns: br-abnt2, us, uk, de, fr, es, it, ru"
# Smart default: br → br-abnt2, outros layouts comuns ficam iguais
defaultConsoleKeyMap="$keyboardLayout"
case "$keyboardLayout" in
  br) defaultConsoleKeyMap="br-abnt2" ;;
  us-intl | intl) defaultConsoleKeyMap="us" ;;
  *)
    if [[ ! "$keyboardLayout" =~ ^(us|uk|de|fr|es|it|ru|dvorak|br-abnt2)$ ]]; then
      defaultConsoleKeyMap="us"
    fi
    ;;
esac
read -rp "Entre com o keymap do console: [ $defaultConsoleKeyMap ] " consoleKeyMap
if [ -z "$consoleKeyMap" ]; then
  consoleKeyMap="$defaultConsoleKeyMap"
fi
echo -e "${GREEN}✓ Console keymap definido: $consoleKeyMap${NC}"

# ---------------------------------------------------------------------------
# Network & Homelab Configuration
# ---------------------------------------------------------------------------
print_header "Network & Homelab Configuration"
echo "🌐 Configure DNS and network settings for LAN-wide homelab access."
echo "   Services will be reachable as https://<service>.<domain> from any"
echo "   device on your network (after pointing the device's DNS to this PC)."
echo ""

# Auto-detect LAN IP
detected_lan_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
if [ -z "$detected_lan_ip" ]; then
  detected_lan_ip="192.168.1.100"
fi

# Auto-detect primary interface
detected_iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
if [ -z "$detected_iface" ]; then
  detected_iface="eth0"
fi

read -rp "Local homelab domain [ homelab.lan ]: " localDomain
if [ -z "$localDomain" ]; then
  localDomain="homelab.lan"
fi
echo -e "${GREEN}✓ Domain: $localDomain${NC}"

read -rp "LAN IP of this machine [ $detected_lan_ip ]: " lanIP
if [ -z "$lanIP" ]; then
  lanIP="$detected_lan_ip"
fi
echo -e "${GREEN}✓ LAN IP: $lanIP${NC}"

read -rp "Network interface [ $detected_iface ]: " networkInterface
if [ -z "$networkInterface" ]; then
  networkInterface="$detected_iface"
fi
echo -e "${GREEN}✓ Interface: $networkInterface${NC}"

tailscaleEnable="false"
echo ""
read -p "Enable Tailscale VPN for remote access? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  tailscaleEnable="true"
  echo -e "${GREEN}✓ Tailscale: enabled${NC}"
  echo -e "${CYAN}  After reboot, run: sudo tailscale up${NC}"
  echo -e "${CYAN}  Or with auth key: sudo tailscale up --authkey=<key>${NC}"
else
  echo -e "${GREEN}✓ Tailscale: disabled (can be enabled later in variables.nix)${NC}"
fi

print_header "Configuring Host and Profile"
mkdir -p hosts/"$hostName"
cp hosts/default/*.nix hosts/"$hostName"

# Show a nice summary and ask for confirmation before making changes
echo ""
print_summary "$hostName" "$profile" "$edition" "$installusername" "$timezone" "$keyboardLayout" "$keyboardVariant" "$consoleKeyMap" "$localDomain" "$lanIP" "$tailscaleEnable"
echo ""
echo -e "${YELLOW}Please review the configuration above.${NC}"
read -p "$(echo -e "${YELLOW}Continue with installation? (Y/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Installation cancelled.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✓ Configuration accepted. Starting installation...${NC}"
echo ""
echo -e "${BLUE}Updating configuration files...${NC}"
echo -e "  ${CYAN}installusername:${NC} $installusername"
echo -e "  ${CYAN}hostName:${NC} $hostName"
echo -e "  ${CYAN}profile:${NC} $profile"
echo -e "  ${CYAN}edition:${NC} $edition"
echo -e "  ${CYAN}timezone:${NC} $timezone"
echo -e "  ${CYAN}keyboardLayout:${NC} $keyboardLayout"

# Update flake.nix (simple pattern replacements that work)
# Create backup first, before any changes
cp ./flake.nix ./flake.nix.bak
# Use sed for hostname (more reliable)
sed -i 's|^[[:space:]]*host[[:space:]]*=[[:space:]]*"[^"]*"|    host = "'$hostName'"|' ./flake.nix.bak
# Use sed for profile (handles variable indentation)
sed -i 's|^[[:space:]]*profile[[:space:]]*=[[:space:]]*"[^"]*";|    profile = "'$profile'";|' ./flake.nix.bak
# Use sed for username (handles variable indentation)
sed -i 's|^[[:space:]]*username[[:space:]]*=[[:space:]]*"[^"]*";|    username = "'$installusername'";|' ./flake.nix.bak
echo -e "${GREEN}After sed replacements:${NC}"
grep -E "(host|profile|username) =" ./flake.nix.bak
cp ./flake.nix.bak ./flake.nix
rm ./flake.nix.bak

# Update variables in host file (do all keys in one pass to avoid quoting issues)
# Now also patches: edition, timeZone (timezone moved from system.nix to variables.nix)
cp ./hosts/$hostName/variables.nix ./hosts/$hostName/variables.nix.bak
awk -v v_user="$gitUsername" \
  -v v_email="$gitEmail" \
  -v v_kb="$keyboardLayout" \
  -v v_kv="$keyboardVariant" \
  -v v_ckm="$consoleKeyMap" \
  -v v_edition="$edition" \
  -v v_tz="$timezone" \
  -v v_domain="$localDomain" \
  -v v_lanip="$lanIP" \
  -v v_iface="$networkInterface" \
  -v v_tailscale="$tailscaleEnable" '
  /^  gitUsername = /       { sub(/"[^"]*"/, "\"" v_user "\"") }
  /^  gitEmail = /          { sub(/"[^"]*"/, "\"" v_email "\"") }
  /^  keyboardLayout = /    { sub(/"[^"]*"/, "\"" v_kb "\"") }
  /^  keyboardVariant = /   { sub(/"[^"]*"/, "\"" v_kv "\"") }
  /^  consoleKeyMap = /     { sub(/"[^"]*"/, "\"" v_ckm "\"") }
  /^  edition = /           { sub(/"[^"]*"/, "\"" v_edition "\"") }
  /^  timeZone = /          { sub(/"[^"]*"/, "\"" v_tz "\"") }
  /^  localDomain = /       { sub(/"[^"]*"/, "\"" v_domain "\"") }
  /^  lanIP = /             { sub(/"[^"]*"/, "\"" v_lanip "\"") }
  /^  networkInterface = /  { sub(/"[^"]*"/, "\"" v_iface "\"") }
  /^  tailscaleEnable = /   { sub(/= (false|true);/, "= " v_tailscale ";") }
  { print }
' ./hosts/$hostName/variables.nix.bak >./hosts/$hostName/variables.nix
rm ./hosts/$hostName/variables.nix.bak

# Apply edition-specific feature flags to variables.nix
# Each edition enables the tools it promises to install.
VARS_FILE="./hosts/$hostName/variables.nix"
set_bool() {
  # set_bool <key> <true|false>
  sed -i "s|^  ${1} = .*;|  ${1} = ${2};|" "$VARS_FILE"
}

case "$edition" in
  basic | medium | full)
    set_bool "vscodeEnable"   "true"
    set_bool "thunarEnable"   "true"
    ;;
  vm)
    # vm edition keeps defaults (minimal — no heavy GUI tools)
    set_bool "vscodeEnable"   "false"
    set_bool "thunarEnable"   "false"
    ;;
esac

echo "Configuration files updated successfully!"


print_header "Git Configuration"
git config --global user.name "$gitUsername"
git config --global user.email "$gitEmail"
git add .
git config --global --unset-all user.name
git config --global --unset-all user.email

print_header "Generating Hardware Configuration -- Ignore ERROR: cannot access /bin"
sudo nixos-generate-config --show-hardware-config >./hosts/$hostName/hardware.nix
git add -f ./hosts/$hostName/hardware.nix
echo -e "${YELLOW}⚠️  hosts/$hostName/hardware.nix was generated for this machine.${NC}"
echo -e "${YELLOW}   This file contains hardware-specific UUIDs and should NOT be committed to git.${NC}"
echo -e "${YELLOW}   It is already listed in .gitignore.${NC}"

print_header "Setting Nix Configuration"
NIX_CONFIG="experimental-features = nix-command flakes"

print_header "Initiating NixOS Build"
read -p "Ready to run initial build? (Y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Build cancelled.${NC}"
  exit 1
fi

sudo nixos-rebuild switch --flake ~/zaneyos/#${profile}
BUILD_STATUS=$?

# ---------------------------------------------------------------------------
# Docker stack deployment — runs only when build succeeded and edition
# requires Docker (basic / medium / full). vm edition skips all stacks.
# ---------------------------------------------------------------------------
deploy_stack() {
  local stack_path="$1"
  local name="$2"
  if [ ! -d "$stack_path" ]; then
    echo -e "  ${YELLOW}⚠️  $name: diretório não encontrado ($stack_path), pulando.${NC}"
    return
  fi
  # Bootstrap .env from .env.example when no .env exists yet
  if [ -f "$stack_path/.env.example" ] && [ ! -f "$stack_path/.env" ]; then
    cp "$stack_path/.env.example" "$stack_path/.env"
    echo -e "  ${CYAN}ℹ  $name: .env criado a partir de .env.example — revise as senhas antes do uso em produção.${NC}"
  fi
  echo -e "  ${CYAN}→ Iniciando $name...${NC}"
  if (cd "$stack_path" && docker compose up -d 2>&1); then
    echo -e "  ${GREEN}✓ $name rodando${NC}"
  else
    echo -e "  ${YELLOW}⚠️  $name falhou. Inicie manualmente: cd $stack_path && docker compose up -d${NC}"
  fi
}

if [ $BUILD_STATUS -eq 0 ]; then
  STACKS_DIR="$HOME/zaneyos/docker/stacks"

  # ---------------------------------------------------------------------------
  # check_network_status — verify DNS, Caddy, and Blocky after build
  # ---------------------------------------------------------------------------
  check_network_status() {
    echo ""
    print_header "Network Status Check"

    echo -e "${CYAN}▶ Blocky DNS service:${NC}"
    if systemctl is-active --quiet blocky 2>/dev/null; then
      echo -e "  ${GREEN}✓ blocky.service is running${NC}"
    else
      echo -e "  ${YELLOW}⚠  blocky.service is not running (may need reboot)${NC}"
    fi

    echo -e "${CYAN}▶ Caddy HTTPS proxy:${NC}"
    if systemctl is-active --quiet caddy 2>/dev/null; then
      echo -e "  ${GREEN}✓ caddy.service is running${NC}"
    else
      echo -e "  ${YELLOW}⚠  caddy.service is not running (may need reboot)${NC}"
    fi

    echo -e "${CYAN}▶ DNS resolution test (portainer.$localDomain → $lanIP):${NC}"
    if command -v dig &>/dev/null; then
      resolved=$(dig +short "portainer.$localDomain" @127.0.0.1 2>/dev/null | head -1)
      if [ "$resolved" = "$lanIP" ]; then
        echo -e "  ${GREEN}✓ DNS resolves correctly ($resolved)${NC}"
      elif [ -n "$resolved" ]; then
        echo -e "  ${YELLOW}⚠  DNS resolved to $resolved (expected $lanIP)${NC}"
      else
        echo -e "  ${YELLOW}⚠  DNS did not resolve (Blocky may need a moment to start)${NC}"
      fi
    else
      echo -e "  ${YELLOW}⚠  dig not available — install bind (zcli rebuild after reboot)${NC}"
    fi

    echo ""
    echo -e "${CYAN}📜 Root CA certificate (install once on each device):${NC}"
    echo -e "  ${BLUE}/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt${NC}"
    echo -e "  See ${BLUE}docs/network.md${NC} for per-platform installation instructions."

    if [ "$tailscaleEnable" = "true" ]; then
      echo ""
      echo -e "${CYAN}🔒 Tailscale VPN:${NC}"
      if systemctl is-active --quiet tailscaled 2>/dev/null; then
        echo -e "  ${GREEN}✓ tailscaled is running${NC}"
        echo -e "  ${CYAN}  Run: sudo tailscale up    to authenticate${NC}"
      else
        echo -e "  ${YELLOW}⚠  tailscaled not running (reboot required)${NC}"
      fi
    fi

    echo ""
    echo -e "${CYAN}💡 Next steps:${NC}"
    echo -e "  1. Reboot: ${BLUE}reboot${NC}"
    echo -e "  2. Set your router's primary DNS to: ${BLUE}$lanIP${NC}"
    echo -e "  3. Install the root CA cert on each device (see docs/network.md)"
    echo -e "  4. Check status: ${BLUE}zcli net-status${NC}"
  }

  case "$edition" in
    vm)
      echo -e "${YELLOW}Edição VM: Docker stacks ignorados (modo minimal).${NC}"
      ;;

    basic)
      print_header "Deploying Docker Stacks — Basic Edition"
      deploy_stack "$STACKS_DIR/homelab/portainer" "Portainer"
      deploy_stack "$STACKS_DIR/homelab/homepage"  "Homepage"
      ;;

    medium)
      print_header "Deploying Docker Stacks — Medium Edition"
      deploy_stack "$STACKS_DIR/homelab/portainer"     "Portainer"
      deploy_stack "$STACKS_DIR/homelab/homepage"      "Homepage"
      deploy_stack "$STACKS_DIR/databases/postgres"    "PostgreSQL"
      deploy_stack "$STACKS_DIR/databases/redis"       "Redis"
      deploy_stack "$STACKS_DIR/monitoring/prometheus" "Prometheus"
      deploy_stack "$STACKS_DIR/monitoring/grafana"    "Grafana"
      deploy_stack "$STACKS_DIR/monitoring/loki"       "Loki"
      deploy_stack "$STACKS_DIR/automation/n8n"        "n8n"
      deploy_stack "$STACKS_DIR/automation/mailpit"    "Mailpit"
      ;;

    full)
      print_header "Deploying Docker Stacks — Full Edition"
      deploy_stack "$STACKS_DIR/homelab/portainer"     "Portainer"
      deploy_stack "$STACKS_DIR/homelab/homepage"      "Homepage"
      deploy_stack "$STACKS_DIR/databases/postgres"    "PostgreSQL"
      deploy_stack "$STACKS_DIR/databases/mysql"       "MySQL"
      deploy_stack "$STACKS_DIR/databases/redis"       "Redis"
      deploy_stack "$STACKS_DIR/databases/cloudbeaver" "CloudBeaver"
      deploy_stack "$STACKS_DIR/databases/adminer"     "Adminer"
      deploy_stack "$STACKS_DIR/monitoring/prometheus" "Prometheus"
      deploy_stack "$STACKS_DIR/monitoring/grafana"    "Grafana"
      deploy_stack "$STACKS_DIR/monitoring/loki"       "Loki"
      deploy_stack "$STACKS_DIR/automation/n8n"        "n8n"
      deploy_stack "$STACKS_DIR/automation/mailpit"    "Mailpit"
      deploy_stack "$STACKS_DIR/storage/minio"         "MinIO"
      deploy_stack "$STACKS_DIR/llm/open-webui"        "Open WebUI (LLM)"
      ;;
  esac

  check_network_status
  print_success_banner
else
  print_failure_banner
fi
