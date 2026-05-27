FROM alpine:3.23.4

ENV KILL_SWITCH=on \
    VPN_LOG_LEVEL=3 \
    HTTP_PROXY=off \
    SOCKS_PROXY=off

RUN apk add --no-cache \
    bind-tools \
    dante-server \
    iptables \
    ip6tables \
    openvpn \
    tinyproxy

RUN mkdir -p /data/vpn

COPY data/ /data

RUN chmod +x /data/scripts/entry.sh \
             /data/scripts/dante_wrapper.sh \
             /data/scripts/tinyproxy_wrapper.sh

HEALTHCHECK CMD ping -c 3 1.1.1.1 || exit 1

ENTRYPOINT ["/data/scripts/entry.sh"]
