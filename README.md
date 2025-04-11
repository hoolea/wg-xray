# WireGuard + XRay VPN

Этот проект объединяет WireGuard и XRay в одном Docker-контейнере для создания локального Wireguard сервера, который перенаправляет трафик на VLESS Reality сервер. Это может быть полезно для маршрутизаторов, которые не поддерживают установку xray, но имеют возможность подключиться к Wireguard серверу.

## Требования

- Установленный Docker и Docker Compose.
- Доступ к серверу с публичным IP-адресом.
- Базовые знания настройки VPN.

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
3. **Соберите Docker-образ**
  ```bash
  docker-compose build
  ```
4. **Запустите контейнер:**
  ```bash
  docker-compose up -d
  ```
5. **Проверьте логи:**
  ```bash
  docker logs wireguard-xray
  ```