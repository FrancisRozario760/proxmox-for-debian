#!/bin/bash
# ==============================================
# Automated Proxmox VE Installer (Debian 12)
# Author: @Notlol95 (Discord) | Modified by CrashCloud
# ==============================================

set -e

echo "=============================================="
echo "  Automated Proxmox VE Installer - Debian 12"
echo "=============================================="
echo ""

# --------------------------
# License Key Verification
# --------------------------
read -p "Please enter a valid key: " key
if [ "$key" != "crashcloud95" ]; then
    echo "❌ Invalid key! Exiting..."
    exit 1
fi
echo "✅ Key verified!"
echo ""

# --------------------------
# Confirm Installation
# --------------------------
read -p "Type (y/n) to confirm installation: " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ Installation aborted!"
    exit 1
fi
echo ""
echo "🚀 Starting Proxmox VE Installation..."
sleep 2

# --------------------------
# Auto-detect Network Config
# --------------------------
IFACE=$(ip route | grep '^default' | awk '{print $5}')
IPADDR=$(ip -4 addr show dev "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
GATEWAY=$(ip route | grep '^default' | awk '{print $3}')
DNS="1.1.1.1"

if [ -z "$IFACE" ] || [ -z "$IPADDR" ] || [ -z "$GATEWAY" ]; then
    echo "❌ Failed to detect network config!"
    exit 1
fi

echo "✅ Detected interface: $IFACE"
echo "✅ Detected IP: $IPADDR"
echo "✅ Detected Gateway: $GATEWAY"
echo ""

# --------------------------
# Configure Host & Network
# --------------------------
HOSTNAME="proxmox-ve"
echo "$HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$HOSTNAME"

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet static
    address $IPADDR
    gateway $GATEWAY
    dns-nameservers $DNS
EOF

# --------------------------
# System Update
# --------------------------
apt update && apt full-upgrade -y
apt install -y wget curl gnupg lsb-release software-properties-common

# --------------------------
# Add Proxmox VE Repo
# --------------------------
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
    > /etc/apt/sources.list.d/pve-install-repo.list

wget -qO - https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/proxmox-release.gpg

apt update

# --------------------------
# Install Proxmox VE
# --------------------------
apt install -y proxmox-ve postfix open-iscsi grub-pc

# --------------------------
# Install GRUB Bootloader
# --------------------------
grub-install /dev/vda || grub-install /dev/sda
update-grub

# --------------------------
# Finish
# --------------------------
echo ""
echo "=============================================="
echo " ✅ Proxmox VE installation is complete!"
echo " 🌐 Web UI: https://$(echo $IPADDR | cut -d/ -f1):8006"
echo "=============================================="
echo ""

read -p "Type 'yes' to reboot now: " reboot_confirm
if [ "$reboot_confirm" == "yes" ]; then
    echo "🔄 Rebooting..."
    reboot
else
    echo "⚠️ Please reboot manually before using Proxmox VE."
fi
