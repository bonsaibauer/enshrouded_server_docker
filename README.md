[![Repository](https://img.shields.io/badge/Repository-enshrouded__server__docker-blue?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker)
![License](https://img.shields.io/badge/License-MIT-blue)
[![Docker Pulls](https://img.shields.io/docker/pulls/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
[![Docker Stars](https://img.shields.io/docker/stars/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/bonsaibauer/enshrouded_server_docker/latest)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=bonsaibauer.enshrouded_server_docker)

[![Report Problem](https://img.shields.io/badge/Report-new_Problem_or_Issue-critical?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker/issues/new)

![GitHub Stars](https://img.shields.io/github/stars/bonsaibauer/enshrouded_server_docker?style=social)
![GitHub Forks](https://img.shields.io/github/forks/bonsaibauer/enshrouded_server_docker?style=social)

<a href="https://github.com/bonsaibauer/enshrouded_server_ubuntu" target="_blank" style="display:inline-block; padding:20px 30px; background-color:#28a745; color:#ffffff; text-decoration:none; border-radius:10px; font-size:18px; font-weight:600; box-shadow:0 8px 20px rgba(0,0,0,0.2);">
  🐧 Use Ubuntu? Go to bonsaibauer/enshrouded_server_ubuntu →
</a>

# Setting Up an Enshrouded Dedicated Server with Docker: A Beginner's Guide

Embark on an adventure in the mystical world of Embervale with your own dedicated **Enshrouded** server. This guide walks you through setting up a dedicated server using **Docker**, making the process consistent and easy across different operating systems.

## Enshrouded: A Vast World of Survival and Magic

**Enshrouded** is an immersive survival action RPG set in a vast, voxel-based open world. Players must explore dangerous lands, craft for survival, and battle mystical creatures. The game supports cooperative multiplayer for up to 16 players, creating the perfect environment for shared adventures.

![Enshrouded Docker Server Setup](images/enshrouded_docker_v2.png)  
<sub>Image generated with the help of [ChatGPT](https://openai.com/chatgpt)</sub>

## Update v1.1 – Wake of the Water 2025-11 release

![Wake of the Water Update](images/update_wake_of_water.jpeg)

- Dynamically simulated water, water tools, and flooding safeguards bring bases to life.
- Veilwater Basin biome, new quests, enemies, and gear raise the progression cap to level 45.
- Fishing, greatswords, rebalanced loot, and workstation force requirements deepen crafting/combat.
- Dedicated servers now expose tags, a visitor role with terraforming limits, and improved admin tools.

### Full Settings + Example Config

- All server/gameplay fields are documented in [`docs/enshrouded_server.md`](docs/enshrouded_server.md).
- A complete sample with every setting populated ships in [`ressources/enshrouded_server.json`](ressources/enshrouded_server.json).

---

## 0. Preparing Your Environment

### Prerequisites

You can run the Enshrouded server inside a Docker container on **any operating system that supports Docker**, including but not limited to:

| Production-Ready Linux               | Desktop/Test Only                  | Notes                                                  |
|-------------------------------------|------------------------------------|--------------------------------------------------------|
| ✅ Ubuntu 24.04 LTS (recommended)   | ✅ macOS (Docker Desktop)          | ⚠️ Not suitable for hosting a live server              |
| ✅ Ubuntu 22.04 LTS                 | ✅ Windows 10/11 (WSL 2 + Docker Desktop) | ⚠️ Use for testing or development only       |
| ✅ Ubuntu 20.04 LTS                 |                                    |                                                        |
| ✅ Debian 12 / 11                   |                                    |                                                        |
| ✅ Fedora 38+                       |                                    |                                                        |
| ✅ Arch Linux                       |                                    | Rolling release — always up-to-date                    |
| ✅ AlmaLinux / Rocky Linux 9 / 8    |                                    | CentOS alternatives                                    |
| ✅ openSUSE Leap / Tumbleweed       |                                    |                                                        |

You’ll need:

- A system with Docker and Docker Compose installed
- sudo or administrative privileges
- `ufw` or firewall configuration (ensure port **15637** is open and forwarded)

# 1. Installing Docker (Ubuntu 24.04 and Other Linux Systems)

Docker allows you to run applications in isolated containers. It's ideal for deploying an Enshrouded dedicated server because it ensures consistency, portability, and easy management.

This guide will walk you through installing Docker on Ubuntu 24.04. These steps also work on most other Linux distributions with minor adjustments.

### Step 1: Update Your Package Index

Before installing anything, update your system to ensure all packages are current.

`Debian/Ubuntu`
```
sudo apt update && sudo apt upgrade -y
```
- `sudo apt update`: Refreshes the package index.
- `sudo apt upgrade -y`: Upgrades installed packages automatically.

> `Fedora`
> ```
> sudo dnf upgrade --refresh
> ```
> 
> `Arch Linux`
> ```
> sudo pacman -Syu
> ```

### Step 2: Install Required Dependencies

Docker relies on a few helper packages. Install them with:

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common lsb-release gnupg -y
```

- `apt-transport-https`: Allows `apt` to use HTTPS.
- `ca-certificates`: Ensures your system trusts SSL certificates.
- `curl`: Command-line tool for downloading files.
- `software-properties-common`: Adds support for `add-apt-repository`.
- `lsb-release`: Provides OS version info.
- `gnupg`: Required for managing GPG keys.

### Step 3: Add Docker’s Official GPG Key

Docker signs its packages for security. Add their GPG key:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Step 4: Add Docker’s APT Repository

Configure your system to use Docker’s stable software repository:

```bash
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]   https://download.docker.com/linux/ubuntu   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Step 5: Install Docker Engine

Update your package index again and install Docker:

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

- `docker-ce`: Docker Community Edition
- `docker-ce-cli`: Docker command-line interface
- `containerd.io`: Container runtime used by Docker

Verify Docker is running:

```bash
sudo systemctl status docker
```

Press `q` to exit the status screen.

# 2. Create user and working directory

To allow the Docker container to persist game data and configurations, we create a dedicated system user and set up the correct directory.

Run these commands as root or with `sudo`:

```bash
# Create a system user 'enshrouded' without login shell
sudo useradd -m -r -s /bin/false enshrouded

# Ensure the home directory exists
sudo mkdir -p /home/enshrouded
sudo mkdir -p /home/enshrouded/enshrouded_server_docker

# Set proper ownership 
sudo chown enshrouded:enshrouded /home/enshrouded/enshrouded_server_docker
```

> 🛡️ This ensures that the container can write to `/home/enshrouded` and all server data stays in one clean location.

# 3. Deploy and Start docker container

Looking for the build-it-yourself workflows? Choose the option that fits best:

- Option (A) Use the Prebuilt Image from Docker Hub (following)
- [Option (B) Launch the Container (Simplified Version)](docs/launch_container_option_b.md)
- [Option (C) Launch the Container (with Environment Variables)](docs/launch_container_option_c.md)

## 3.1 Option: (A) Use the Prebuilt Image from Docker Hub

If you prefer not to build the image yourself, you can run the **official prebuilt Docker image** directly from Docker Hub. This is the fastest and easiest way to get your server up and running.

### Run the Server Using the Docker Hub Image:

```bash
docker run -d \
  --name enshroudedserver \
  --restart=always \
  -p 15637:15637/udp \
  -e ENSHROUDED_USER_ID="$(id -u enshrouded)" \
  -e ENSHROUDED_USER_ID="$(id -g enshrouded)" \  
  -v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded \
  bonsaibauer/enshrouded_server_docker:latest
```

### Explanation:
> - `bonsaibauer/enshrouded_server_docker:latest` is the **official prebuilt image** available on Docker Hub  
> - You **don’t need to build the image yourself**, just pull and run it  
> - The rest of the parameters are the same as in Option B and C
> - `ENSHROUDED_USER_ID="$(id -u enshrouded)"` needed to set the correct User ID for enshrouded inside the container
> - `ENSHROUDED_GROUP_ID="$(id -g enshrouded)"` needed to set the correct Group ID for enshrouded inside the container
>
> ✅ **Tip:** Configuration (`enshrouded_server.json`) is done in the mounted directory `/home/enshrouded/enshrouded_server_docker` as usual.

---

### Monitoring Enshrouded Docker Server Logs for successful start
> ```bash
> docker logs -f enshroudedserver
> ```
> The `-f` flag means "follow", which shows real-time output.
> 
> Wait until you see the following logs to confirm it's running:
> 
> ```bash
> [Session] 'HostOnline' (up)!
> [Session] finished transition from 'Lobby' to 'Host_Online' (current='Host_Online')!
> ```
> 
> To exit the log view safely and keep the server running, press:
> 
> ```bash
> Ctrl + C
> ```

[Go to „4. Edit server configuration“](#4-edit-server-configuration)

---

### Run the Server Using Environmental Variables:

```bash
docker run -d \
  --name enshroudedserver \
  --restart=always \
  -p 15637:15637/udp \
  -v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded \
  -e ENSHROUDED_USER_ID="$(id -u enshrouded)" \
  -e ENSHROUDED_USER_ID="$(id -g enshrouded)" \  
  -e ENSHROUDED_SERVER_NAME="myservername" \
  -e ENSHROUDED_SERVER_MAXPLAYERS=16 \
  -e ENSHROUDED_VOICE_CHAT_MODE="Proximity" \
  -e ENSHROUDED_ENABLE_VOICE_CHAT=false \
  -e ENSHROUDED_ENABLE_TEXT_CHAT=false \
  -e ENSHROUDED_GAME_PRESET="Default" \
  -e ENSHROUDED_ADMIN_PW="AdminXXXXXXXX" \
  -e ENSHROUDED_FRIEND_PW="FriendXXXXXXXX" \
  -e ENSHROUDED_GUEST_PW="GuestXXXXXXXX" \
  bonsaibauer/enshrouded_server_docker:latest
```

### Explanation of Environmental Variables
> - `-d`: Run in detached mode (in the background).
> - `--name enshroudedserver`: Names the container “enshroudedserver”.
> - `--restart=always`: Automatically restarts the container if it stops or the host reboots.
> - `-p 15637:15637/udp`: Maps the UDP port 15637 from the container to the host, required for the game server.
> - `-v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded`: Mounts a local directory for persistent data and configuration.
> - `ENSHROUDED_USER_ID="$(id -u enshrouded)"` needed to set the correct User ID for enshrouded inside the container
> - `ENSHROUDED_GROUP_ID="$(id -g enshrouded)"` needed to set the correct Group ID for enshrouded inside the container
> - `-e ENSHROUDED_SERVER_NAME="myservername"`: Sets the server's visible name.
> - `-e ENSHROUDED_SERVER_MAXPLAYERS=16`: Limits the number of players to 16.
> - `-e ENSHROUDED_VOICE_CHAT_MODE="Proximity"`: Enables proximity-based voice chat.
> - `-e ENSHROUDED_ENABLE_VOICE_CHAT=false`: Disables voice chat (this overrides the mode setting).
> - `-e ENSHROUDED_ENABLE_TEXT_CHAT=false`: Disables text chat in-game.
> - `-e ENSHROUDED_GAME_PRESET="Default"`: Sets the game rules preset.
> - `-e ENSHROUDED_ADMIN_PW="AdminXXXXXXXX"`: Password for admin access.
> - `-e ENSHROUDED_FRIEND_PW="FriendXXXXXXXX"`: Password for friends to join.
> - `-e ENSHROUDED_GUEST_PW="GuestXXXXXXXX"`: Password for guest access.
> - `bonsaibauer/enshrouded_server_docker:latest`: The Docker Hub image used to run the server.
> 
> 💡 **Tip:** You can skip the `-e` environment variables if you prefer to manage all server settings later in the `enshrouded_server.json` file inside the mounted volume.

# 4. Edit server configuration

> 🔧 This file is located in the mounted directory:
> `/home/enshrouded/enshrouded_server_docker/enshrouded_server.json`

```bash
nano enshrouded_server.json
```

Edit the `enshrouded_server.json` file to configure your server settings.

---

### General Server Settings

| Setting            | Description                                | Example / Default Value | Options / Notes          |
|--------------------|--------------------------------------------|--------------------------|---------------------------|
| **name**           | Name of the server                         | "Enshrouded Server"      | Any string                |
| **saveDirectory**  | Directory where savegames are stored       | "./savegame"             | File path                 |
| **logDirectory**   | Directory for log files                    | "./logs"                 | File path                 |
| **ip**             | Server IP binding                          | "0.0.0.0"                | Server ip adress          |
| ...                | ...                                        | ...                      | ...                       |

... [View full server settings here](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/enshrouded_server.md)

> **ℹ️ Note: Nano editor**
>
> After editing the `enshrouded_server.json` file, follow these steps to save your changes and exit the Nano editor:
>
> 1. **Save**:
>    - Press `CTRL + O` (this means "Write Out").
>    - Press `Enter` to confirm and save the file with the current name.
>
> 2. **Exit**:
>    - Press `CTRL + X` to close the Nano editor.
>
> You will then return to the regular command line.

# 5. Docker commands to manage Enshrouded Server
## Start the Enshrouded Server

If the container has already been created (e.g. from a previous `docker run`), you can start it again with:

```bash
docker start enshroudedserver
```

## Stop the Enshrouded Server

To safely stop the server without deleting the container:

```bash
docker stop enshroudedserver
```

## Update the Enshrouded Server

To restart the container (stop and start again):

```bash
docker restart enshroudedserver
```

## Stop and remove the container
   ```bash
   docker stop enshroudedserver
   docker rm enshroudedserver
   ```

## Buy Me A Coffee
If this project has helped you in any way, do buy me a coffee so I can continue to build more of such projects in the future and share them with the community!

<a href="https://buymeacoffee.com/bonsaibauer" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

