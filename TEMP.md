






Looking for the build-it-yourself workflows? Choose the option that fits best:

- Option (A) Quickstart docker run 
- Option (B) Quickstart docker run (with environment variables)
  
## 2.1 Option: (A) Use the Prebuilt Image from Docker Hub

If you prefer not to build the image yourself, you can run the **official prebuilt Docker image** directly from Docker Hub. This is the fastest and easiest way to get your server up and running.

### Step 1: Go to ...
```bash
cd /home/enshrouded/server_1
```

### Step 2: Deploy and run Docker Image

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  --stop-timeout 90 \
  -p 15637:${ENSHROUDED_QUERY_PORT:=15637}/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e ENSHROUDED_QUERY_PORT \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:dev_latest
```

## 2.2 Option: (B) Run the Server Using Environmental Variables

--- 

## Step 2: (not necessary)

<details>
<summary><strong>Visual guide (changeable parts marked with <>):</strong></summary>

```bash
docker run \
  --name <container_name> \
  --restart=unless-stopped \
  -p <host_port>:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="<profile>" \
  -e MANAGER_PROFILE="<profile>" \
  -e ENSHROUDED_NAME="<server_name>" \
  -e ENSHROUDED_ROLE_0_PASSWORD="<admin_password>" \
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
| `-e ENSHROUDED_NAME` | `-e ENSHROUDED_NAME="My Enshrouded Server"` |
| `-e ENSHROUDED_ROLE_0_PASSWORD` | `-e ENSHROUDED_ROLE_0_PASSWORD="MyAdminPassword"` |
| `-v <host_path>:/home/steam/enshrouded` | `-v /srv/enshrouded:/home/steam/enshrouded` |
| `bonsaibauer/enshrouded_server_docker:<tag>` | `bonsaibauer/enshrouded_server_docker:latest` (see [Docker Hub tags](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker/tags)) |
</details>

---

Wait until you see the following logs to confirm it's running:
```bash
[Session] 'HostOnline' (up)!
[Session] finished transition from 'Lobby' to 'Host_Online' (current='Host_Online')!
```

To exit the log view safely and keep the server running, press:
```bash
Ctrl + C
```

---

# 4. Edit server configuration
> 🔧 This file is located in the mounted directory:
> `/home/enshrouded/server_1/enshrouded_server.json`

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

## View live logs

Follow the server logs in real time (use `Ctrl+C` to leave log view; the container keeps running):

```bash
docker logs -f enshroudedserver
```

--- 

## Buy Me A Coffee
If this project has helped you in any way, do buy me a coffee so I can continue to build more of such projects in the future and share them with the community!

<a href="https://buymeacoffee.com/bonsaibauer" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

