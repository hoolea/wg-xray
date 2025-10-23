# WireGuard + XRay

Этот проект объединяет WireGuard и XRay в одном Docker-контейнере для создания локального Wireguard сервера, который перенаправляет трафик на VLESS Reality сервер. Это может быть полезно для маршрутизаторов, которые не поддерживают установку xray, но имеют возможность подключиться к Wireguard серверу.

## Требования

- Установленный Docker и Docker Compose.
- Доступ к серверу с публичным IP-адресом.

## Установка

Следуйте этим шагам, чтобы развернуть контейнер:

1. **Клонируйте репозиторий**:
   ```bash
   git clone https://github.com/hoolea/wg-xray.git
   cd wg-xray
2. **Отредактируйте файл с переменными .env:**
  ```
  WG_PRIVATE_KEY=<your server private key>
  WG_PEER_PUBLIC_KEY=<your peer public key>
  WG_PORT=27855
  WG_IP=10.66.66.1
  WG_PEER_IP=10.66.66.2
  VLESS_ADDRESS=<ip vless server>
  VLESS_UUID=<your id>
  XRAY_PUBLIC_KEY=<your public key>
  XRAY_SHORT_ID=<your short id>
  XRAY_SERVERNAME=yandex.ru
  ```
3. **Настройка Xray health monitor**
В файле entrypoint.sh отредактируйте строку на любой удобный для вас адрес. В случае недоступности скрипт выключает icmp на интерфейсе wg0, а уже на маршрутизаторе отследив это - сделать автоматизацию выключения маршрутов, bgp и тд.
```bash
    TEST_URL="https://rutracker.org" # <---- Адрес сайта для проверки тунеля
```
4. **Соберите Docker-образ**
  ```bash
  docker-compose build
  ```
5. **Запустите контейнер:**
  ```bash
  docker-compose up -d
  ```
6. **Проверьте логи:**
  ```bash
  docker logs wireguard-xray
  ```
7. **Выполните команды на хосте:**
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.route_localnet=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
**net.ipv4.ip_forward=1** - включает IP-переадресацию (routing) на уровне ядра Linux.
**net.ipv4.conf.all.route_localnet=1** - разрешает маршрутизацию пакетов, адресованных локальным адресам (127.0.0.0/8), через интерфейсы.
**sysctl -p** - Применяет (загружает) параметры из /etc/sysctl.conf без перезагрузки системы.
