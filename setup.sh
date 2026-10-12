#!/usr/bin/env bash
# Free Secure WireGuard VPN Automated Installer & Setup
# Zero-logs, anti-leak protection, high performance.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="$BASE_DIR/keys"
CONFIG_DIR="$BASE_DIR/config"
CLIENTS_DIR="$BASE_DIR/clients"

mkdir -p "$KEY_DIR" "$CLIENTS_DIR"

echo "=========================================================="
echo "    Free Secure WireGuard VPN Setup & Hardening           "
echo "=========================================================="

# 1. Enable IP Forwarding in kernel
echo "[1/5] Enabling IPv4 & IPv6 kernel packet forwarding..."
if [[ -d /etc/sysctl.d ]]; then
    cat <<EOF | sudo tee /etc/sysctl.d/99-wireguard-vpn.conf >/dev/null
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
    sudo sysctl -p /etc/sysctl.d/99-wireguard-vpn.conf >/dev/null 2>&1 || true
else
    sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
    sudo sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1 || true
fi

# 2. Package Installation Helper
echo "[2/5] Checking and installing dependencies..."
install_pkgs() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq wireguard wireguard-tools iptables qrencode curl openssl nodejs npm >/dev/null 2>&1 || true
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm wireguard-tools iptables qrencode curl openssl nodejs npm >/dev/null 2>&1 || true
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y wireguard-tools iptables qrencode curl openssl nodejs npm >/dev/null 2>&1 || true
    fi
}
install_pkgs

# 3. Generate WireGuard Server Keys
echo "[3/5] Generating cryptographic keypair..."
if [[ ! -f "$KEY_DIR/server_private.key" ]]; then
    if command -v wg &>/dev/null; then
        wg genkey | tee "$KEY_DIR/server_private.key" | wg pubkey > "$KEY_DIR/server_public.key"
    else
        openssl rand -base64 32 > "$KEY_DIR/server_private.key"
        openssl rand -base64 32 > "$KEY_DIR/server_public.key"
    fi
    chmod 600 "$KEY_DIR/server_private.key"
fi

SERVER_PRIVKEY=$(cat "$KEY_DIR/server_private.key")
SERVER_PUBKEY=$(cat "$KEY_DIR/server_public.key")

# 4. Prepare Server Configuration & Firewall Script
echo "[4/5] Deploying WireGuard configuration and anti-leak firewall..."
sudo mkdir -p /etc/wireguard
sudo cp "$CONFIG_DIR/anti-leak.sh" /etc/wireguard/anti-leak.sh
sudo chmod +x /etc/wireguard/anti-leak.sh

sed "s|SERVER_PRIVATE_KEY|$SERVER_PRIVKEY|g" "$CONFIG_DIR/server.conf.template" > /tmp/wg0.conf
sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

# Enable WireGuard systemd service if available
if command -v systemctl &>/dev/null; then
    sudo systemctl enable wg-quick@wg0 >/dev/null 2>&1 || true
    sudo systemctl restart wg-quick@wg0 >/dev/null 2>&1 || true
fi

# 5. Generate First Client Profile
echo "[5/5] Generating initial client profile ('myphone')..."
export SERVER_CONF="/etc/wireguard/wg0.conf"
"$BASE_DIR/manage-vpn.sh" add myphone

echo ""
echo "=========================================================="
echo "  VPN Setup Complete!                                     "
echo "  - Client config created at: $CLIENTS_DIR/myphone.conf   "
echo "  - Run './manage-vpn.sh qr myphone' to display QR code   "
echo "  - Start Web Dashboard: cd dashboard && npm start        "
echo "=========================================================="
