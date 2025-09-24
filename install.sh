#!/bin/bash

# ==============================
# Automated Proxmox VE Installer
# For Debian 12
# Author: @Notlol95 (Discord)
# ==============================

set -e

# Welcome message
echo "=============================================="
echo " Hi User, Thanks for Using This Script!"
echo " (Automated Script By discord @Notlol95)"
echo "=============================================="
echo ""

# Key verification
read -p "Please enter a valid key: " key
if [ "$key" != "crashcloud95" ]; then
    echo "Invalid key! Exiting..."
    exit 1
fi

echo "Key verified successfully!"
echo ""

# Password prompt
read -s -p "Enter PASSWORD: " password
echo ""
echo "PASSWORD entered."
read -p "Type (y/n) to confirm installation: " confirm
if [ "$confirm" != "y" ]; then
    echo "Installation aborted!"
    exit 1
fi

echo ""
echo "Starting Proxmox VE Installation..."
sleep 2

# --------------------------
# Auto-detect Network Config
# --------------------------

# Detect main network interface
IFACE=$(ip route | grep '^default' | awk '{print $5}')
if [ -z "$IFACE" ]; then
    echo "❌ Could not detect network interface!"
    exit 1
fi

# Detect IP address
IPADDR=$(ip -4 addr show dev "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
if [ -z "$IPADDR" ]; then
    echo "❌ Could not detect IP address!"
    exit 1
fi

# Detect Gateway
GATEWAY=$(ip route | grep '^default' | awk '{print $3}')
if [ -z "$GATEWAY" ]; then
    echo "❌ Could not detect gateway!"
    exit 1
fi

# DNS fallback
DNS="1.1.1.1"

echo "✅ Detected interface: $IFACE"
echo "✅ Detected IP: $IPADDR"
echo "✅ Detected Gateway: $GATEWAY"
echo "✅ Using DNS: $DNS"
echo ""

# --------------------------
# Proxmox Installation Steps
# --------------------------

# Set hostname
HOSTNAME="proxmox-ve"
echo "$HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$HOSTNAME"

# Configure network
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet static
    address $IPADDR
    gateway $GATEWAY
    dns-nameservers $DNS
EOF

# Update system
apt update && apt full-upgrade -y

# Add Proxmox VE repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
wget -qO - https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/proxmox-release.gpg

# Install Proxmox VE
apt update && apt install -y proxmox-ve postfix open-iscsi

# Ask which disk to wipe
echo ""
lsblk
read -p "Enter the disk to install Proxmox on (e.g., /dev/sda): " DISK
if [ -b "$DISK" ]; then
    echo "⚠️ WARNING: This will wipe $DISK completely!"
    read -p "Type 'yes' to continue: " wipe_confirm
    if [ "$wipe_confirm" == "yes" ]; then
        sgdisk --zap-all "$DISK"
    else
        echo "Disk wipe skipped!"
    fi
else
    echo "❌ Invalid disk selected!"
fi

# Finish
echo ""
echo "=============================================="
echo " ✅ Proxmox VE installation is complete!"
echo " Web UI will be available at: https://$(echo $IPADDR | cut -d/ -f1):8006"
echo "=============================================="
echo ""

# Ask before reboot
read -p "Type 'yes' to reboot now: " reboot_confirm
if [ "$reboot_confirm" == "yes" ]; then
    echo "Rebooting..."
    reboot
else
    echo "Reboot skipped. Please reboot manually later."
fi
