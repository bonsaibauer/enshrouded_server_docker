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
- Automatic restart on system reboot (`--restart=always`)
- Minimal or fully customized server setup options

---

## 🧪 Quickstart

```bash
docker run -d \
  --name enshroudedserver \
  --restart=always \
  -p 15637:15637/udp \
  -v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded \
  bonsaibauer/enshrouded_server_docker:latest
```

👉 Make sure to open **UDP port 15637** on your firewall/router.

---

## ⚙️ Configuration

Configure the server via file:

```
/home/enshrouded/enshrouded_server_docker/enshrouded_server.json
```

👉 **Note**: You do not need change server IP inside the JSON file (`"ip": "YOUR.IP.ADDRESS"`) to ensure it’s discoverable.

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

---

## ☕ Support the Developer

If this helped you, consider buying a coffee:  
[buymeacoffee.com/bonsaibauer](https://buymeacoffee.com/bonsaibauer)