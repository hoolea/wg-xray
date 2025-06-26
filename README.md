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
## Замечание
Заметил что после перезагрузки хоста пропадает пересылка пакетов между подсетью хоста и docker сети.
Для сохранения настроек нужно выполнить следующие команды:
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.route_localnet=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
Отвалы и дисконект после перезагрузки пропали.
