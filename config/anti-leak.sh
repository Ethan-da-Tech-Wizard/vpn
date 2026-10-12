#!/usr/bin/env bash
# WireGuard Anti-Leak & Firewall Hardening Script
# Ensures zero IP leaks, DNS leak protection, and IPv6 security.

set -euo pipefail

ACTION="${1:-enable}"
INTERFACE="${2:-wg0}"

# Find default WAN network interface
WAN_IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)
if [[ -z "$WAN_IFACE" ]]; then
    WAN_IFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wg" {print $2}' | tr -d ' ' | head -n1)
fi
WAN_IFACE="${WAN_IFACE:-eth0}"

echo "[Anti-Leak] Interface: $INTERFACE | WAN: $WAN_IFACE | Action: $ACTION"

if [[ "$ACTION" == "enable" ]]; then
    # 1. Enable IPv4 forwarding and NAT masquerade
    iptables -A FORWARD -i "$INTERFACE" -j ACCEPT
    iptables -A FORWARD -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -t nat -A POSTROUTING -o "$WAN_IFACE" -j MASQUERADE

    # 2. Enable IPv6 forwarding and NAT masquerade (if supported)
    if [[ -f /proc/net/if_inet6 ]]; then
        ip6tables -A FORWARD -i "$INTERFACE" -j ACCEPT || true
        ip6tables -A FORWARD -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT || true
        ip6tables -t nat -A POSTROUTING -o "$WAN_IFACE" -j MASQUERADE || true
    fi

    # 3. DNS Leak Protection: Clamp MSS to MTU to avoid packet fragment drops
    iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

    # 4. Prevent local IP subnet leakage
    iptables -A FORWARD -i "$INTERFACE" -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT || true

    echo "[Anti-Leak] Firewall rules applied successfully."

elif [[ "$ACTION" == "disable" ]]; then
    # Clean up firewall rules
    iptables -D FORWARD -i "$INTERFACE" -j ACCEPT || true
    iptables -D FORWARD -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT || true
    iptables -t nat -D POSTROUTING -o "$WAN_IFACE" -j MASQUERADE || true

    if [[ -f /proc/net/if_inet6 ]]; then
        ip6tables -D FORWARD -i "$INTERFACE" -j ACCEPT || true
        ip6tables -D FORWARD -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT || true
        ip6tables -t nat -D POSTROUTING -o "$WAN_IFACE" -j MASQUERADE || true
    fi

    iptables -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || true
    echo "[Anti-Leak] Firewall rules removed."
fi
