#!/usr/bin/env bash

######################################
# Install script for zaneyos  
# Author:  Don Williams 
# Date: June 27, 2005 
#######################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Function to print an error message
print_error() {
  echo -e "${RED}Error: ${1}${NC}"
}

# Function to print a success banner
print_success_banner() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                 zaneyos Installation Successful!                      ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a failure banner
print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                 zaneyos Installation Failed!                          ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║   Please review the log file for details:                             ║${NC}"
  echo -e "${RED}║   ${LOG_FILE}                                                        ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_header "Verifying System Requirements"

# Check for git
if ! command -v git &> /dev/null; then
  print_error "Git is not installed."
  echo -e "Please install git and pciutils are installed, then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

# Check for lspci (pciutils)
if ! command -v lspci &> /dev/null; then
  print_error "pciutils is not installed."
  echo -e "Please install git and pciutils,  then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

# Check for python3 (required for helper scripts)
if ! command -v python3 &> /dev/null; then
  print_error "python3 is not installed."
  echo -e "Please install python3, then re-run the install script."
  echo -e "Example: nix-shell -p python3"
  exit 1
fi

if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
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
read -rp "Enter Your New Hostname: [ default ] " hostName
if [ -z "$hostName" ]; then
  hostName="default"
fi

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
  elif $has_nvidia && $has_intel; then
    DETECTED_PROFILE="nvidia-laptop"
  elif $has_nvidia && $has_amd; then
    DETECTED_PROFILE="amd-hybrid"
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
read -rp "Enter Your Hardware Profile (GPU)\nOptions:\n[ amd ]\nnvidia\nnvidia-laptop\namd-hybrid\nintel\nvm\nPlease type out your choice: " profile
  if [ -z "$profile" ]; then
    profile="amd"
  fi
  echo -e "${GREEN}Selected GPU profile: $profile${NC}"
fi

print_header "Backup Existing zaneyos (if any)"

backupname=$(date +"%Y-%m-%d-%H-%M-%S")
if [ -d "zaneyos" ]; then
  echo -e "${GREEN}zaneyos exists, backing up to .config/zaneyos-backups folder.${NC}"
  if [ -d ".config/zaneyos-backups" ]; then
    echo -e "${GREEN}Moving current version of zaneyos to backups folder.${NC}"
    mv "$HOME"/zaneyos .config/zaneyos-backups/"$backupname"
    sleep 1
  else
    echo -e "${GREEN}Creating the backups folder & moving zaneyos to it.${NC}"
    mkdir -p .config/zaneyos-backups
    mv "$HOME"/zaneyos .config/zaneyos-backups/"$backupname"
    sleep 1
  fi
else
  echo -e "${GREEN}Thank you for choosing zaneyos.${NC}"
  echo -e "${GREEN}I hope you find your time here enjoyable!${NC}"
fi

# Use the repository where this script lives; no extra git clone needed
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
print_header "Using local ZaneyOS repository at: $REPO_DIR"
cd "$REPO_DIR" || exit 1

print_header "Configuring Host and Profile"
mkdir -p hosts/"$hostName"
cp hosts/default/*.nix hosts/"$hostName"

installusername=$(echo $USER)
git config --global user.name "$installusername"
git config --global user.email "$installusername@gmail.com"
git add .
git config --global --unset-all user.name
git config --global --unset-all user.email

sed -i "/^[[:space:]]*host[[:space:]]*=[[:space:]]*\"/ s/\"[^\"]*\"/\"$hostName\"/" ./flake.nix
sed -i "/^[[:space:]]*profile[[:space:]]*=[[:space:]]*\"/ s/\"[^\"]*\"/\"$profile\"/" ./flake.nix

print_header "Keyboard Layout Configuration"
read -rp "Enter your keyboard layout: [ us ] " keyboardLayout
if [ -z "$keyboardLayout" ]; then
  keyboardLayout="us"
fi
sed -i "/^[[:space:]]*keyboardLayout[[:space:]]*=[[:space:]]*\"/ s/\"[^\"]*\"/\"$keyboardLayout\"/" ./hosts/$hostName/variables.nix

print_header "Console Keymap Configuration"
read -rp "Enter your console keymap: [ us ] " consoleKeyMap
if [ -z "$consoleKeyMap" ]; then
  consoleKeyMap="us"
fi
sed -i "/^[[:space:]]*consoleKeyMap[[:space:]]*=[[:space:]]*\"/ s/\"[^\"]*\"/\"$consoleKeyMap\"/" ./hosts/$hostName/variables.nix

print_header "Username Configuration"
sed -i "/^[[:space:]]*username[[:space:]]*=[[:space:]]*\"/ s/\"[^\"]*\"/\"$installusername\"/" ./flake.nix

print_header "Generating Hardware Configuration -- Ignore ERROR: cannot access /bin"
sudo nixos-generate-config --show-hardware-config > ./hosts/$hostName/hardware.nix

print_header "Bootloader Configuration"
mirror_boot=false
if grep -q '"/boot2"' "./hosts/$hostName/hardware.nix"; then
  mirror_boot=true
elif [ -f /etc/nixos/hardware-configuration.nix ] && grep -q '"/boot2"' /etc/nixos/hardware-configuration.nix; then
  mirror_boot=true
fi

grub_in_current=false
if [ -f /etc/nixos/configuration.nix ] && grep -q 'boot\.loader\.grub\.enable[[:space:]]*=[[:space:]]*true' /etc/nixos/configuration.nix; then
  grub_in_current=true
fi

get_device_for_mount() {
  local mountpoint="$1"
  local device=""
  if [ -f "./hosts/$hostName/hardware.nix" ]; then
    device=$(sed -n "/fileSystems\\.\"${mountpoint//\//\\/}\"/,/};/p" "./hosts/$hostName/hardware.nix" | sed -n 's/.*device = "\(.*\)".*/\1/p' | head -n 1)
  fi
  if [ -z "$device" ] && [ -f /etc/nixos/hardware-configuration.nix ]; then
    device=$(sed -n "/fileSystems\\.\"${mountpoint//\//\\/}\"/,/};/p" /etc/nixos/hardware-configuration.nix | sed -n 's/.*device = "\(.*\)".*/\1/p' | head -n 1)
  fi
  if [ -z "$device" ] && command -v findmnt >/dev/null 2>&1; then
    device=$(findmnt -no SOURCE "$mountpoint" 2>/dev/null | head -n 1)
  fi
  echo "$device"
}

boot_device=$(get_device_for_mount "/boot")
boot2_device=$(get_device_for_mount "/boot2")

if $mirror_boot || $grub_in_current; then
  vars_file="./hosts/$hostName/variables.nix"
  python3 - <<PY
from pathlib import Path
import re

vars_path = Path("$vars_file")
text = vars_path.read_text()

text = re.sub(r"^\\s*bootLoader\\s*=.*\\n", "", text, flags=re.M)
text = re.sub(r"^\\s*grubMirroredBoots\\s*=\\s*\\[[\\s\\S]*?^\\s*];\\n", "", text, flags=re.M)

boot = ${boot_device@Q}
boot2 = ${boot2_device@Q}

insert_lines = [
    '    bootLoader = "grub";',
]
if $mirror_boot and boot and boot2:
    insert_lines += [
        '    grubMirroredBoots = [',
        f'      {{ path = "/boot"; devices = [ "{boot}" ]; }}',
        f'      {{ path = "/boot2"; devices = [ "{boot2}" ]; }}',
        '    ];',
    ]
elif boot:
    insert_lines += [
        '    grubMirroredBoots = [',
        f'      {{ path = "/boot"; devices = [ "{boot}" ]; }}',
        '    ];',
    ]

insert = "\\n".join(insert_lines) + "\\n"
text, n = re.subn(r"(^\\s*zaneyos\\s*=\\s*\\{\\n)", r"\\1" + insert, text, count=1, flags=re.M)
if n == 0:
    raise SystemExit("Could not find zaneyos block to insert bootloader settings")

vars_path.write_text(text)
PY

  if $mirror_boot && [ -n "$boot_device" ] && [ -n "$boot2_device" ]; then
    echo -e "${GREEN}Detected mirrored /boot and /boot2; configuring GRUB with mirroredBoots.${NC}"
  elif $mirror_boot; then
    echo -e "${RED}Detected /boot2 but could not resolve devices; enabling GRUB without mirroredBoots.${NC}"
  else
    echo -e "${GREEN}Detected GRUB-based system; configuring GRUB.${NC}"
  fi
else
  echo -e "${GREEN}No mirrored /boot2 and no GRUB detected; leaving bootloader defaults.${NC}"
fi

print_header "Setting Nix Configuration"
NIX_CONFIG="experimental-features = nix-command flakes"

print_header "Initiating NixOS Build"
read -p "Ready to run initial build? (Y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Build cancelled.${NC}"
    exit 1
fi

sudo nixos-rebuild boot --flake ~/zaneyos/#${hostName}

# Check the exit status of the last command (nixos-rebuild)
if [ $? -eq 0 ]; then
  print_success_banner
else
  print_failure_banner
fi
