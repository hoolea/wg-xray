FROM alpine:3.18

RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    iproute2 \
    curl \
    unzip \
    gettext \
    && mkdir -p /etc/xray /var/log/xray \
    && curl -L "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" -o /tmp/xray.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
