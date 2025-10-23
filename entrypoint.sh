#!/bin/bash
set -Eeuo pipefail

# -------------------------------
# Проверка обязательных переменных
# -------------------------------
for var in WG_PRIVATE_KEY WG_PEER_PUBLIC_KEY WG_PORT WG_IP WG_PEER_IP VLESS_UUID XRAY_PUBLIC_KEY XRAY_SERVERNAME; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

# -------------------------------
# Подготовка конфигов
# -------------------------------
envsubst < /etc/wireguard/wg0.conf.template > /etc/wireguard/wg0.conf
envsubst < /etc/xray/config.json.template > /etc/xray/config.json

# -------------------------------
# Настройка iptables
# -------------------------------
iptables -F
iptables -t nat -F
iptables -t nat -A PREROUTING -i wg0 -p udp -j DNAT --to-destination 127.0.0.1:10800
iptables -t nat -A PREROUTING -i wg0 -p tcp -j DNAT --to-destination 127.0.0.1:10800
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -s "${WG_IP}/24" -o eth0 -j MASQUERADE
iptables -A INPUT -i lo -j ACCEPT

# -------------------------------
# Функции блокировки/разблокировки ICMP
# -------------------------------
block_icmp() {
    echo "$(date) - Blocking ICMP on wg0 (Xray down)"
    iptables -C INPUT -i wg0 -p icmp -j DROP 2>/dev/null || iptables -I INPUT -i wg0 -p icmp -j DROP
    iptables -C FORWARD -i wg0 -p icmp -j DROP 2>/dev/null || iptables -I FORWARD -i wg0 -p icmp -j DROP
}

unblock_icmp() {
    echo "$(date) - Unblocking ICMP on wg0 (Xray up)"
    iptables -D INPUT -i wg0 -p icmp -j DROP 2>/dev/null || true
    iptables -D FORWARD -i wg0 -p icmp -j DROP 2>/dev/null || true
}

# -------------------------------
# Функция запуска Xray
# -------------------------------
start_xray() {
    echo "$(date) - Starting Xray..."
    /usr/local/bin/xray run -c /etc/xray/config.json &
    XRAY_PID=$!
}

# -------------------------------
# Запуск WireGuard
# -------------------------------
echo "$(date) - Starting WireGuard..."
wg-quick up /etc/wireguard/wg0.conf

# -------------------------------
# Ждём пока Xray-прокси готов
# -------------------------------
start_xray
echo "$(date) - Waiting for Xray proxy to start..."
until nc -z 127.0.0.1 10801; do
    sleep 1
done
echo "$(date) - Xray proxy started"

# -------------------------------
# Цикл проверки Xray через прокси
# -------------------------------
check_loop() {
    set +e
    INTERVAL=20
    FAILS_THRESHOLD=3
    fail_count=0
    TEST_URL="https://rutracker.org" # <---- Адрес сайта для проверки тунеля
    LOG_FILE="/var/log/xray-health.log"

    echo "$(date) - Starting Xray health monitor..." | tee -a "$LOG_FILE"

    while true; do
        if curl -x http://127.0.0.1:10801 --max-time 5 --fail -s -o /dev/null "$TEST_URL"; then
            if [ $fail_count -ge $FAILS_THRESHOLD ]; then
                unblock_icmp
            fi
            fail_count=0
            echo "$(date) - Xray OK" | tee -a "$LOG_FILE"
        else
            ((fail_count++))
            echo "$(date) - Xray unreachable, fail_count=$fail_count" | tee -a "$LOG_FILE"
            if [ $fail_count -ge $FAILS_THRESHOLD ]; then
                block_icmp
            fi
        fi
        sleep "$INTERVAL"
    done
}

# -------------------------------
# Запуск health-check и контроль
# -------------------------------
check_loop &
CHECK_PID=$!

# -------------------------------
# Основной цикл
# -------------------------------
while true; do

    if ! kill -0 "$XRAY_PID" 2>/dev/null; then
        echo "$(date) - Xray process died, restarting..." | tee -a /var/log/xray-health.log
        start_xray
    fi


    if ! kill -0 "$CHECK_PID" 2>/dev/null; then
        echo "$(date) - Health-check died, restarting..." | tee -a /var/log/xray-health.log
        check_loop &
        CHECK_PID=$!
    fi

    sleep 10
done
