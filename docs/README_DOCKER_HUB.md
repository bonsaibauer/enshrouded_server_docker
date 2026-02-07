[![Made With Love](https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F-by%20bonsaibauer-green)](https://github.com/bonsaibauer)&nbsp;&nbsp;

[![Repository](https://img.shields.io/badge/Repository-enshrouded__server__docker-blue?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker)&nbsp;&nbsp;
![License](https://img.shields.io/badge/License-MIT-blue)&nbsp;&nbsp;

[![Docker Pulls](https://img.shields.io/docker/pulls/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)&nbsp;&nbsp;
[![Docker Stars](https://img.shields.io/docker/stars/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)&nbsp;&nbsp;
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/bonsaibauer/enshrouded_server_docker/latest)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)



[![Report Problem](https://img.shields.io/badge/Report-new_Problem_or_Issue-critical?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker/issues/new)

![GitHub Stars](https://img.shields.io/github/stars/bonsaibauer/enshrouded_server_docker?style=social)
![GitHub Forks](https://img.shields.io/github/forks/bonsaibauer/enshrouded_server_docker?style=social)

# Enshrouded Dedicated Server – Docker Image

🚀 Start your own **dedicated Enshrouded server** in seconds – cross-platform and easy using Docker!

**Enshrouded** is a cooperative survival action RPG set in a vast voxel-based open world with up to 16 players. This Docker image makes hosting your own server quick and easy – perfect for friends, communities, or hosting providers.

---

## 🔧 Features

- Official image: `bonsaibauer/enshrouded_server_docker`
- Persistent storage and config via mounted volumes
- Configure via `enshrouded_server.json` or environment variables
- Auto-restarts after crash/reboot; if you stop it manually, it stays stopped until you start it (`--restart=unless-stopped`)
- Minimal or fully customized server setup options

---

## 🧪 Quickstart

### Create user and working directory

To allow the Docker container to persist game data and configurations, we create a dedicated system user and set up the correct directory.

Run these commands as root or with `sudo`:

Create the system user:

```bash
sudo useradd -m -r -s /bin/false enshrouded
```
- `useradd -m -r -s /bin/false enshrouded`: creates a system user with a home directory and no login shell.

Ensure the home directory exists:

```bash
sudo mkdir -p /home/enshrouded/server_1
```
- `mkdir -p /home/enshrouded/server_1`: creates the persistent data directory.

Set proper ownership:

```bash
sudo chown -R enshrouded:enshrouded /home/enshrouded/server_1
```
- `chown -R enshrouded:enshrouded /home/enshrouded/server_1`: assigns ownership to the enshrouded user (recursive so existing files are fixed too).

Ensure group write access:

```bash
sudo chmod -R u+rwX,g+rwX /home/enshrouded/server_1
```
- `chmod -R u+rwX,g+rwX /home/enshrouded/server_1`: ensures logs/saves are writable by the mapped user and group.

Add the current login user to the enshrouded group (same access as enshrouded):

```bash
sudo usermod -aG enshrouded "${SUDO_USER:-$USER}"
```
- `usermod -aG enshrouded "${SUDO_USER:-$USER}"`: grants the current login user the same access as enshrouded.

Allow the enshrouded user to run docker without sudo:

```bash
sudo usermod -aG docker enshrouded
```
- `usermod -aG docker enshrouded`: lets enshrouded run docker without sudo.

Apply group changes without logging out:

```bash
newgrp enshrouded
newgrp docker
```
- `newgrp enshrouded` / `newgrp docker`: applies group changes in the current session (each opens a new shell; run the one you need, or open a new terminal for the other).

> 🛡️ This ensures that the container can write to `/home/enshrouded/server_1` and all server data stays in one clean location.
> PUID/PGID are required at container start to map the internal user to your host `enshrouded` user.


Go to ...
```bash
cd /home/enshrouded/server_1
```

Start the container:

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="default" \
  -e MANAGER_PROFILE="default" \
  -v /home/enshrouded/server_1:/home/steam/enshrouded \
  bonsaibauer/enshrouded_server_docker:latest
```

Visual guide (changeable parts marked with <>):

```bash
docker run \
  --name <container_name> \
  --restart=unless-stopped \
  -p <host_port>:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="<profile>" \
  -e MANAGER_PROFILE="<profile>" \
  -v <host_path>:/home/steam/enshrouded \
  bonsaibauer/enshrouded_server_docker:<tag>
```

Common adjustments:

| Item | Example |
| --- | --- |
| `--name <container_name>` | `--name enshroudedserver` |
| `--restart=unless-stopped` | Keeps the container running across reboots and crashes (e.g. `no`, `on-failure`, `always`, `unless-stopped`). |
| `-p <host_port>:15637/udp` | `-p 25000:15637/udp` (external UDP 25000) |
| `-e PUID/PGID` | In this tutorial: `-e PUID=$(id -u enshrouded) -e PGID=$(id -g enshrouded)`; you can also set them individually, e.g. `-e PUID=1001 -e PGID=1001`. |
| `-e EN_PROFILE` | `-e EN_PROFILE=default` (applied only when `enshrouded_server.json` is created for the first time). |
| `-e MANAGER_PROFILE` | `-e MANAGER_PROFILE=default` (profile is copied to `/server_manager/server_manager.json` when missing or a stub). |
| `-v <host_path>:/home/steam/enshrouded` | `-v /srv/enshrouded:/home/steam/enshrouded` |
| `bonsaibauer/enshrouded_server_docker:<tag>` | `bonsaibauer/enshrouded_server_docker:latest` (see [Docker Hub tags](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker/tags)) |

👉 Make sure to open **UDP port 15637** on your firewall/router.
👉 Keep using the same `/home/enshrouded/server_1` (or your chosen folder) to preserve saves/configs; adjust the `-v` path accordingly.

---

## ⚙️ Configuration

Configure the server via file:

```
/home/enshrouded/server_1/enshrouded_server.json   # adjust `server_1` if you mounted a different folder
```

Server Manager config and data live under the mounted `/server_manager/` directory:

```
/home/enshrouded/server_1/server_manager/server_manager.json
/home/enshrouded/server_1/server_manager/manager-bootstrap.log
/home/enshrouded/server_1/server_manager/run/
```

Profile files are stored at:

```
/home/enshrouded/server_1/profile/<name>/server_manager.json
```

👉 **Note**: In the normal case just leave `"ip": "0.0.0.0"` — the server stays reachable without adding your public IP.

---

## 🐳 Docker Management Commands

```bash
docker logs -f enshroudedserver      # View server logs
docker stop enshroudedserver         # Stop the server
docker start enshroudedserver        # Start the server
docker restart enshroudedserver      # Restart the server
```

---

## 📁 GitHub & Documentation

Code & Full Guide:  
🔗 [bonsaibauer/enshrouded_server_docker](https://github.com/bonsaibauer/enshrouded_server_docker)

Server Manager profiles:  
📄 [docs/server_manager_profiles.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/server_manager_profiles.md)

Enshrouded server profiles:  
📄 [docs/enshrouded_profiles.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/enshrouded_profiles.md)

---

## ☕ Support the Developer

If this helped you, consider buying a coffee:  
[buymeacoffee.com/bonsaibauer](https://buymeacoffee.com/bonsaibauer)
