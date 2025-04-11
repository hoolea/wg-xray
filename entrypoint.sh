#!/bin/bash

# Check var
for var in WG_PRIVATE_KEY WG_PEER_PUBLIC_KEY WG_PORT WG_IP WG_PEER_IP VLESS_UUID XRAY_PUBLIC_KEY XRAY_SERVERNAME; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

envsubst < /etc/wireguard/wg0.conf.template > /etc/wireguard/wg0.conf
envsubst < /etc/xray/config.json.template > /etc/xray/config.json

iptables -F
iptables -t nat -F
iptables -t nat -A PREROUTING -i wg0 -p udp -j DNAT --to-destination 127.0.0.1:10800
iptables -t nat -A PREROUTING -i wg0 -p tcp -j DNAT --to-destination 127.0.0.1:10800
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -s "${WG_IP}/24" -o eth0 -j MASQUERADE
iptables -A INPUT -i lo -j ACCEPT

wg-quick up /etc/wireguard/wg0.conf || { echo "Failed to start WireGuard"; exit 1; }

exec /usr/local/bin/xray run -c /etc/xray/config.json
