# OpenVPN Client for Docker

A containerized OpenVPN client built on Alpine Linux with a built-in kill switch, an HTTP proxy ([Tinyproxy](https://tinyproxy.github.io/)) and a SOCKS proxy ([Dante](https://www.inet.no/dante/index.html)).
This allows hosts and non-containerized applications to use the VPN without running a VPN client on each host.

## What is this and what does it do?

The kill switch is implemented with `iptables`: if the VPN tunnel drops for any reason, all non-local traffic is blocked until the tunnel is restored.

Any VPN provider is supported — just supply the OpenVPN configuration file(s).

## Why?

Having a containerized VPN client lets you choose which applications use the VPN via container networking instead of configuring split tunnelling on each host.
It also avoids installing an OpenVPN client on the underlying host.

## How do I use it?

### Getting the image

Build the image locally:

```
docker build -t openvpn-client ./build
```

### Creating and running a container

The container requires the `NET_ADMIN` capability and access to `/dev/net/tun`.

#### `docker run`

```
docker run --detach \
  --name=openvpn-client \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  --volume <path/to/vpn/config>:/vpn:ro \
  openvpn-client
```

#### `docker-compose`

```yaml
services:
  openvpn-client:
    build: ./build
    container_name: openvpn-client
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      - KILL_SWITCH=on
      - HTTP_PROXY=off
      - SOCKS_PROXY=off
    volumes:
      - <path/to/vpn/config>:/vpn:ro
    ports:
      - "8080:8080"   # Tinyproxy HTTP proxy (when HTTP_PROXY=on)
      - "1080:1080"   # Dante SOCKS proxy   (when SOCKS_PROXY=on)
    restart: unless-stopped
```

#### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `KILL_SWITCH` | `on` | Enable/disable the iptables kill switch. |
| `SUBNETS` | | Comma-separated list of subnets (e.g. `192.168.0.0/24,10.0.0.0/8`) allowed outside the VPN tunnel. |
| `VPN_LOG_LEVEL` | `3` | OpenVPN verbosity level (1–11). |
| `HTTP_PROXY` | `off` | Set to `on` to start the Tinyproxy HTTP proxy on port **8080**. |
| `SOCKS_PROXY` | `off` | Set to `on` to start the Dante SOCKS5 proxy on port **1080**. |
| `PROXY_USERNAME` | | Username for proxy authentication. Must be paired with `PROXY_PASSWORD`. |
| `PROXY_PASSWORD` | | Password for proxy authentication. Must be paired with `PROXY_USERNAME`. |
| `PROXY_USERNAME_SECRET` | | Name of the Docker secret containing the proxy username. |
| `PROXY_PASSWORD_SECRET` | | Name of the Docker secret containing the proxy password. |
| `OPENVPN_AUTH_SECRET` | | Name of the Docker secret containing the OpenVPN `auth-user-pass` credentials file. |

##### `SUBNETS`

> **Important:** if the kill switch is enabled, the DNS server used by the container before the VPN connects must be included in `SUBNETS`.
> The kill switch blocks all traffic outside the tunnel before it is established, so an unallowed DNS server will prevent VPN hostnames from resolving.

##### `HTTP_PROXY` and `SOCKS_PROXY`

When enabling a proxy, publish the corresponding port:

```yaml
ports:
  - "<host_port>:8080"   # HTTP proxy
  - "<host_port>:1080"   # SOCKS proxy
```

##### `PROXY_USERNAME_SECRET` and `PROXY_PASSWORD_SECRET`

Compose supports [Docker secrets](https://docs.docker.com/engine/swarm/secrets/#use-secrets-in-compose).
See the [docker-compose.yml](docker-compose.yml) in this repository for an example.

### Using with other containers

Once `openvpn-client` is running, other containers can use its network stack:

1. **Same Compose file** — add `network_mode: service:openvpn-client` to the service definition.
2. **Different Compose file** — add `network_mode: container:openvpn-client`.
3. **`docker run`** — add `--network=container:openvpn-client`.

To expose a port of a connected container, publish it on the `openvpn-client` service:

```yaml
ports:
  - "<host_port>:<container_port>"
```

### Verifying functionality

```
docker run --rm -it --network=container:openvpn-client alpine wget -qO - ifconfig.me
```

You should see an IP address belonging to your VPN provider.

### Troubleshooting

#### VPN credentials

If your OpenVPN configuration requires credentials, create a file next to the `.conf` / `.ovpn` file (e.g. `credentials.txt`):

```
vpn_username
vpn_password
```

Then add this line to the OpenVPN configuration file:

```
auth-user-pass credentials.txt
```

Alternatively, pass the credentials as a Docker secret via `OPENVPN_AUTH_SECRET`.

