#!/usr/bin/env bash
# WireGuard Client Management CLI
# Manage VPN users, generate configs, and display QR codes for mobile devices.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENTS_DIR="$BASE_DIR/clients"
SERVER_CONF="${SERVER_CONF:-/etc/wireguard/wg0.conf}"
KEY_DIR="$BASE_DIR/keys"

mkdir -p "$CLIENTS_DIR" "$KEY_DIR"

# Detect public IP address
SERVER_IP=$(curl -s4 https://ifconfig.me || curl -s4 https://api.ipify.org || echo "YOUR_SERVER_PUBLIC_IP")
SERVER_PORT=51820
DNS_RESOLVERS="1.1.1.1, 9.9.9.9"

# Helper for generating wireguard keypair
gen_keys() {
    if command -v wg &>/dev/null; then
        PRIVKEY=$(wg genkey)
        PUBKEY=$(echo "$PRIVKEY" | wg pubkey)
        PSK=$(wg genpsk)
    else
        # Fallback key generator using OpenSSL if wg CLI is absent
        PRIVKEY=$(openssl rand -base64 32)
        PUBKEY=$(echo "$PRIVKEY" | sha256sum | awk '{print $1}' | x86_64-linux-gnu-head -c 44 2>/dev/null || echo "$PRIVKEY" | sha256sum | head -c 44)
        PSK=$(openssl rand -base64 32)
    fi
}

show_help() {
    cat <<EOF
WireGuard VPN Client Manager

Usage:
  ./manage-vpn.sh add <client_name>     Add a new VPN client profile
  ./manage-vpn.sh list                  List all configured clients
  ./manage-vpn.sh revoke <client_name>  Remove/revoke a client profile
  ./manage-vpn.sh qr <client_name>      Show QR code for mobile scanning
  ./manage-vpn.sh status                Show server status and active connections
  ./manage-vpn.sh help                  Show this help screen
EOF
}

get_next_ip() {
    local used_ips
    used_ips=$(grep -oE '10\.8\.0\.[0-9]+' "$BASE_DIR/clients/*.conf" 2>/dev/null || echo "10.8.0.1")
    for i in {2..254}; do
        if ! echo "$used_ips" | grep -q "10.8.0.$i$"; then
            echo "10.8.0.$i"
            return 0
        fi
    done
    echo "10.8.0.254"
}

cmd_add() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Error: Client name required. Example: ./manage-vpn.sh add myphone"
        exit 1
    fi

    # Sanitize client name
    name=$(echo "$name" | sed 's/[^a-zA-Z0-9_-]//g')
    local conf_file="$CLIENTS_DIR/${name}.conf"

    if [[ -f "$conf_file" ]]; then
        echo "Warning: Client '$name' already exists at $conf_file"
        cmd_qr "$name"
        return 0
    fi

    # Load or generate server public key
    local server_pubkey
    if [[ -f "$KEY_DIR/server_public.key" ]]; then
        server_pubkey=$(cat "$KEY_DIR/server_public.key")
    else
        server_pubkey="SERVER_PUBLIC_KEY_PLACEHOLDER"
    fi

    # Generate client keys
    gen_keys
    local client_privkey="$PRIVKEY"
    local client_pubkey="$PUBKEY"
    local psk_key="$PSK"
    local client_ip
    client_ip=$(get_next_ip)
    local ip_num=${client_ip##*.}

    # Write client config file
    cat <<EOF > "$conf_file"
[Interface]
PrivateKey = $client_privkey
Address = $client_ip/32, fd86:ea04:1111::$ip_num/128
DNS = $DNS_RESOLVERS

[Peer]
PublicKey = $server_pubkey
PresharedKey = $psk_key
Endpoint = ${SERVER_IP}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

    echo "Successfully created client profile: $name"
    echo "Configuration saved to: $conf_file"
    echo "Assigned IP: $client_ip"
    echo ""

    # Append to server configuration if present
    if [[ -f "$SERVER_CONF" ]]; then
        cat <<EOF >> "$SERVER_CONF"

# Client: $name
[Peer]
PublicKey = $client_pubkey
PresharedKey = $psk_key
AllowedIPs = $client_ip/32, fd86:ea04:1111::$ip_num/128
EOF
        if command -v wg &>/dev/null && systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
            wg syncconf wg0 <(wg-quick strip wg0 2>/dev/null || cat "$SERVER_CONF") || true
        fi
    fi

    cmd_qr "$name"
}

cmd_list() {
    echo "=== Configured VPN Clients ==="
    if ! ls "$CLIENTS_DIR"/*.conf &>/dev/null; then
        echo "No clients created yet."
        return 0
    fi

    printf "%-18s %-16s %-30s\n" "CLIENT NAME" "IP ADDRESS" "CONFIG PATH"
    printf "%-18s %-16s %-30s\n" "-----------" "----------" "-----------"

    for file in "$CLIENTS_DIR"/*.conf; do
        local cname
        cname=$(basename "$file" .conf)
        local cip
        cip=$(grep -E '^Address' "$file" | awk '{print $3}' | cut -d',' -f1)
        printf "%-18s %-16s %-30s\n" "$cname" "$cip" "$file"
    done
}

cmd_qr() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Error: Client name required."
        exit 1
    fi
    local conf_file="$CLIENTS_DIR/${name}.conf"
    if [[ ! -f "$conf_file" ]]; then
        echo "Error: Profile '$name' not found."
        exit 1
    fi

    echo "=== QR Code for Client: $name ==="
    if command -v qrencode &>/dev/null; then
        qrencode -t ansiutf8 < "$conf_file"
    elif python3 -c "import qrcode" &>/dev/null; then
        python3 -c "import qrcode, sys; qr = qrcode.QRCode(); qr.add_data(open('$conf_file').read()); qr.print_ascii(tty=True)"
    else
        echo "(Install 'qrencode' or python 'qrcode' package to display terminal QR code)"
        echo "You can import the raw configuration file:"
        echo "----------------------------------------"
        cat "$conf_file"
        echo "----------------------------------------"
    fi
}

cmd_revoke() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Error: Client name required to revoke."
        exit 1
    fi
    local conf_file="$CLIENTS_DIR/${name}.conf"
    if [[ -f "$conf_file" ]]; then
        rm -f "$conf_file"
        echo "Removed configuration file for '$name'."
    else
        echo "Client configuration file not found."
    fi

    if [[ -f "$SERVER_CONF" ]]; then
        sed -i "/# Client: $name/,+5d" "$SERVER_CONF" 2>/dev/null || true
        echo "Revoked peer '$name' from WireGuard server config."
        if command -v wg &>/dev/null && systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
            wg-quick strip wg0 > /tmp/wg0.tmp 2>/dev/null && wg syncconf wg0 /tmp/wg0.tmp && rm -f /tmp/wg0.tmp || true
        fi
    fi
}

cmd_status() {
    echo "=== WireGuard Server Status ==="
    if command -v wg &>/dev/null; then
        wg show || echo "WireGuard is installed but not running."
    else
        echo "WireGuard kernel module/tool ('wg') is not active on this environment."
        echo "Server Public IP: $SERVER_IP"
        echo "Configured Clients count: $(ls -1 "$CLIENTS_DIR"/*.conf 2>/dev/null | wc -l)"
    fi
}

case "${1:-help}" in
    add) cmd_add "${2:-}" ;;
    list) cmd_list ;;
    qr) cmd_qr "${2:-}" ;;
    revoke) cmd_revoke "${2:-}" ;;
    status) cmd_status ;;
    help|*) show_help ;;
esac
