#!/bin/bash

set -e

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 0. Check if KVM is supported
echo -e "${YELLOW}[+] install cpu-checker for kvm-ok ...${NC}"
sudo apt update
sudo apt install -y cpu-checker

echo -e "${YELLOW}[+] Checking KVM support...${NC}"
if ! kvm-ok > /dev/null 2>&1; then
  echo -e "${YELLOW}[!] KVM is not supported or not enabled in BIOS. Exiting.${NC}"
  exit 1
fi

# 1. Install prerequisites
echo -e "${YELLOW}[+] Installing prerequisites...${NC}"
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system virt-manager

# 2. Add current user to the libvirt group
USER_NAME=$(whoami)
echo -e "${YELLOW}[+] Adding user '$USER_NAME' to 'libvirt' group...${NC}"
sudo usermod -aG libvirt "$USER_NAME"

# 3. Download Debian Cloud image if not already downloaded or if corrupted
IMG_NAME="debian-12-genericcloud-amd64-daily.qcow2"
IMG_URL="https://cloud.debian.org/images/cloud/bookworm/daily/latest/$IMG_NAME"
SHA256SUM_URL="https://cloud.debian.org/images/cloud/bookworm/daily/latest/SHA512SUMS"

DOWNLOAD_IMAGE() {
  echo -e "${YELLOW}[+] Downloading Ubuntu image...${NC}"
  wget -O "$IMG_NAME" "$IMG_URL"
}

VERIFY_CHECKSUM() {
  echo -e "${YELLOW}[+] Verifying checksum...${NC}"
  wget -O SHA512SUMS "$SHA256SUM_URL"
  if sha512sum -c --ignore-missing SHA512SUMS; then
    echo -e "${YELLOW}[+] Checksum verification successful.${NC}"
    rm -f SHA512SUMS
    return 0
  else
    echo -e "${YELLOW}[!] Checksum verification failed.${NC}"
    rm -f SHA512SUMS
    return 1
  fi
}

if [ -f "$IMG_NAME" ]; then
  if VERIFY_CHECKSUM; then
    echo -e "${YELLOW}[+] Image '$IMG_NAME' already exists and checksum is valid.${NC}"
  else
    echo -e "${YELLOW}[!] Image exists but checksum verification failed. Re-downloading...${NC}"
    rm -f "$IMG_NAME"
    DOWNLOAD_IMAGE
    VERIFY_CHECKSUM
  fi
else
  DOWNLOAD_IMAGE
  VERIFY_CHECKSUM
fi

# 4. Resize the image by +20G
echo -e "${YELLOW}[+] Resizing image '$IMG_NAME' by +20G...${NC}"
qemu-img resize "$IMG_NAME" +20G

# 8. Show absolute path to use in Terraform variables
ABSOLUTE_PATH=$(readlink -f "$IMG_NAME")
echo -e "${YELLOW}[+] Use this absolute path in your Terraform 'variables.tf':${NC}"
echo "  $ABSOLUTE_PATH"

# 5. Ask user if they want to automatically update variables.tf
echo -e "${YELLOW}[?] Do you want to automatically update 'variables.tf' with this path? (y/N):${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}[+] Updating variables.tf...${NC}"
  # Create a backup of the original file
  cp variables.tf variables.tf.backup
  # Update the default value in variables.tf
  sed -i "s|default = \".*\"|default = \"$ABSOLUTE_PATH\"|" variables.tf
  echo -e "${YELLOW}[+] Updated variables.tf with the absolute path.${NC}"
  echo -e "${YELLOW}[+] Original file backed up as variables.tf.backup${NC}"
else
  echo -e "${YELLOW}[+] Skipping automatic update. Please manually update variables.tf with the path above.${NC}"
fi

echo -e "${YELLOW}[+] Done. Please log out and log back in for group membership changes to take effect.${NC}"
