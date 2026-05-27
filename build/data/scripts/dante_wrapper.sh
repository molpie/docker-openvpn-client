#!/bin/ash
# shellcheck shell=ash
# shellcheck disable=SC2169 # making up for lack of ash support

echo -e "Running Dante SOCKS proxy server.\n"

until ip link show 2>&1 | grep -qE '^[0-9]+: tun[0-9]+:'; do
    sleep 1
done

sockd -f /data/sockd.conf
