[![Repository](https://img.shields.io/badge/Repository-enshrouded__server__docker-blue?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker)
![License](https://img.shields.io/badge/License-MIT-blue)
[![Docker Pulls](https://img.shields.io/docker/pulls/bonsaibauer/enshrouded_server_docker.svg)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
[![Docker Stars](https://img.shields.io/docker/stars/bonsaibauer/enshrouded_server_docker.svg)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/bonsaibauer/enshrouded_server_docker/latest)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)

[![Report Problem](https://img.shields.io/badge/Report-new_Problem_or_Issue-critical?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker/issues/new)
[![Discussions](https://img.shields.io/badge/Discussions-Share_Ideas-blue?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker/discussions/new/choose)

![GitHub Stars](https://img.shields.io/github/stars/bonsaibauer/enshrouded_server_docker?style=social)
![GitHub Forks](https://img.shields.io/github/forks/bonsaibauer/enshrouded_server_docker?style=social)

# Setting Up an Enshrouded Dedicated Server on Ubuntu: A Beginner's Guide

Embark on an adventure in the mystical world of Embervale with your own dedicated Enshrouded server. This guide will walk you through setting up a dedicated server for Enshrouded on Ubuntu, ensuring you and your friends can enjoy this survival action RPG to its fullest.

## Enshrouded: A Vast World of Survival and Magic

Enshrouded is an immersive survival action RPG set in a vast, voxel-based open world. Players must navigate through dangerous terrains, craft items for survival, and battle against various creatures. The game supports cooperative play for up to 16 players, allowing for a shared adventure in the magical world of Embervale.

![Enshrouded Ubuntu Server Setup](enshrouded_ubuntu.png)
<sub>Image generated with the help of [ChatGPT](https://openai.com/chatgpt)</sub>

# 0. Preparing Your Environment

## Prerequisites

- ✅ Ubuntu 22.04 (While these steps are written for Ubuntu, they should also work if you wanted to set up an Enshrouded server on other Linux distributions such as Debian.)
- ✅ Ubuntu 24.04 (tested)
- sudo privileges
- ufw settings (Please note that the Enshrouded dedicated server uses port 15637 by default. You must port forward to allow outside access to your server. Additionally, if you are using a firewall such as UFW you will need to allow these port.)

### System Update

Ensure your Ubuntu system is up-to-date to avoid any compatibility issues.

```bash
sudo apt update
sudo apt upgrade -y
```

### Install Required Packages



Install essential packages for setting up your server.
## Buy Me A Coffee
If this project has helped you in any way, do buy me a coffee so I can continue to build more of such projects in the future and share them with the community!

<a href="https://buymeacoffee.com/bonsaibauer" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
