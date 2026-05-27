#!/bin/ash
# shellcheck shell=ash
# shellcheck disable=SC2169 # making up for lack of ash support

echo -e "Running Dante SOCKS proxy server.\n"

until ip link show 2>&1 | grep -qE '^[0-9]+: tun[0-9]+:'; do
    sleep 1
done

tun_iface=$(ip link show 2>&1 | grep -oE 'tun[0-9]+' | head -1)
sed -i "s/^external: tun[0-9]*/external: $tun_iface/" /data/sockd.conf

sockd -f /data/sockd.conf
