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

# Function to print a configuration summary (robust formatting)
print_summary() {
  local hostname="$1" profile="$2" user="$3" tz="$4" layout="$5" variant="$6" console="$7"
  local v
  v="${variant:-none}"
  printf "%b\n" "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  printf "%b\n" "${CYAN}║                 📋 Installation Configuration Summary                 ║${NC}"
  printf "%b\n" "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
  printf "%b\n" "${CYAN}║  🖥️  Hostname:        ${BLUE}${hostname}${NC}"
  printf "%b\n" "${CYAN}║  🎮 GPU Profile:      ${BLUE}${profile}${NC}"
  printf "%b\n" "${CYAN}║  👤 System Username:  ${BLUE}${user}${NC}"
  printf "%b\n" "${CYAN}║  🌐 Timezone:         ${BLUE}${tz}${NC}"
  printf "%b\n" "${CYAN}║  ⌨️  Keyboard Layout:  ${BLUE}${layout}${NC}"
  printf "%b\n" "${CYAN}║  ⌨️  Keyboard Variant: ${BLUE}${v}${NC}"
  printf "%b\n" "${CYAN}║  🖥️  Console Keymap:   ${BLUE}${console:-$layout}${NC}"
  printf "%b\n" "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print an error message
print_error() {
  echo -e "${RED}Error: ${1}${NC}"
}

# Function to print a success banner
print_success_banner() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                 ZaneyOS Installation Successful!                      ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a failure banner
print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                 ZaneyOS Installation Failed!                          ║${NC}"
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

# Check for python3 (required for helper scripts)
if ! command -v python3 &>/dev/null; then
  print_error "python3 is not installed."
  echo -e "Please install python3, then re-run the install script."
  echo -e "Example: nix-shell -p python3"
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

print_header "Repository Setup"

backupname=$(date +"%Y-%m-%d-%H-%M-%S")
if [ -d "$HOME/zaneyos" ]; then
  echo -e "${YELLOW}Backing up existing zaneyos-${backupname}${NC}"
  mv "$HOME/zaneyos" "$HOME/zaneyos-${backupname}"
fi

print_header "Cloning ZaneyOS Repository"
git clone https://gitlab.com/zaney/zaneyos.git -b zos-next-grub --depth=1 ~/zaneyos
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
echo "🌎 Common timezones:"
echo "  • US: America/New_York, America/Chicago, America/Denver, America/Los_Angeles"
echo "  • Europe: Europe/London, Europe/Berlin, Europe/Paris, Europe/Rome"
echo "  • Asia: Asia/Tokyo, Asia/Shanghai, Asia/Seoul, Asia/Kolkata"
echo "  • Australia: Australia/Sydney, Australia/Melbourne"
echo "  • UTC (Universal): UTC"
read -rp "Enter your timezone [ America/New_York ]: " timezone
if [ -z "$timezone" ]; then
  timezone="America/New_York"
fi
echo -e "${GREEN}✓ Timezone set to: $timezone${NC}"

print_header "Keyboard Layout Configuration"
echo "🌍 Common keyboard layouts:"
echo "  • us (US English) - default"
echo "  • us-intl (US International)"
echo "  • uk (UK English)"
echo "  • de (German)"
echo "  • fr (French)"
echo "  • es (Spanish)"
echo "  • it (Italian)"
echo "  • ru (Russian)"
echo "  • dvorak (Dvorak)"
read -rp "Enter your keyboard layout: [ us ] " keyboardLayout
if [ -z "$keyboardLayout" ]; then
  keyboardLayout="us"
fi
echo -e "${GREEN}✓ Keyboard layout set to: $keyboardLayout${NC}"

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
echo "⌨️  Console keymap (usually matches your keyboard layout):"
echo "  Most common: us, uk, de, fr, es, it, ru"
# Smart default: use keyboard layout as console keymap default if it's a common one
defaultConsoleKeyMap="$keyboardLayout"
if [[ ! "$keyboardLayout" =~ ^(us|uk|de|fr|es|it|ru|us-intl|dvorak)$ ]]; then
  defaultConsoleKeyMap="us"
fi
read -rp "Enter your console keymap: [ $defaultConsoleKeyMap ] " consoleKeyMap
if [ -z "$consoleKeyMap" ]; then
  consoleKeyMap="$defaultConsoleKeyMap"
fi
echo -e "${GREEN}✓ Console keymap set to: $consoleKeyMap${NC}"

print_header "Configuring Host and Profile"
mkdir -p hosts/"$hostName"
cp hosts/default/*.nix hosts/"$hostName"

# Show a nice summary and ask for confirmation before making changes
echo ""
print_summary "$hostName" "$profile" "$installusername" "$timezone" "$keyboardLayout" "$keyboardVariant" "$consoleKeyMap"
echo ""
echo -e "${YELLOW}Please review the configuration above.${NC}"
printf "%b" "${YELLOW}Continue with installation? (Y/N): ${NC}"
read -r REPLY
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Installation cancelled.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✓ Configuration accepted. Starting installation...${NC}"
echo ""
echo -e "${BLUE}Updating configuration files...${NC}"

# Update flake.nix safely without removing existing hosts
cp ./flake.nix ./flake.nix.bak

# 1) Update username if present
sed -i -E "s|^[[:space:]]*username[[:space:]]*=[[:space:]]*\"[^\"]*\";|    username = \"${installusername}\";|" ./flake.nix

# 2) Ensure the new host is listed in the hosts array (append if missing)
awk -v h="$hostName" '
  BEGIN { in_hosts=0; seen=0 }
  /^\s*hosts\s*=\s*\[/ { in_hosts=1 }
  in_hosts && /"[^"]+"/ {
    if (index($0, "\"" h "\"") > 0) seen=1
  }
  in_hosts && /\];/ {
    if (!seen) print "      \"" h "\""
    in_hosts=0
  }
  { print }
' ./flake.nix >./flake.nix.tmp && mv ./flake.nix.tmp ./flake.nix

# (quiet) flake updated

# Update timezone in system.nix (robust quoting via Python helper)
cp ./modules/core/system.nix ./modules/core/system.nix.bak
python3 ./scripts/update_timezone.py ./modules/core/system.nix "$timezone" || {
  print_error "Failed to update time.timeZone in modules/core/system.nix"
  exit 1
}
rm ./modules/core/system.nix.bak

# Update variables in host file; support both old style and new zaneyos options block
cp ./hosts/$hostName/variables.nix ./hosts/$hostName/variables.nix.bak
python3 ./scripts/update_vars.py "./hosts/$hostName/variables.nix" \
  "$gitUsername" "$gitEmail" "$hostName" "$profile" "$keyboardLayout" "$keyboardVariant" "$consoleKeyMap" || {
  print_error "Failed to update hosts/$hostName/variables.nix"
  echo "Check the file exists and the script at ./scripts/update_vars.py is present."
  exit 1
}
rm ./hosts/$hostName/variables.nix.bak

echo "Configuration files updated successfully!"

print_header "Git Configuration"
git config --global user.name "$gitUsername"
git config --global user.email "$gitEmail"
git add .
git config --global --unset-all user.name
git config --global --unset-all user.email

print_header "Generating Hardware Configuration"
sudo nixos-generate-config --show-hardware-config >./hosts/$hostName/hardware.nix

print_header "Setting Nix Configuration"
NIX_CONFIG="experimental-features = nix-command flakes"

print_header "Initiating NixOS Build"
printf "%s" "Ready to run initial build? [y/N]: "
read -r REPLY
if ! [[ "$REPLY" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Build cancelled.${NC}"
  exit 1
fi

# Build using the selected HOST (GPU profile is configured inside the host files)
sudo nixos-rebuild boot --flake ~/zaneyos#${hostName}

# Check the exit status of the last command (nixos-rebuild)
if [ $? -eq 0 ]; then
  print_success_banner
else
  print_failure_banner
fi
