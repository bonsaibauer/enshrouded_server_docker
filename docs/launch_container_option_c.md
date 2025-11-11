# 3.3 Option (C) Launch the Container (with Environment Variables)

This command runs the Enshrouded dedicated server using Docker and sets several environment variables directly when launching the container.

## Step 1: Download the repository

Change to the working directory:

```bash
cd /home/enshrouded
```

Clone the project from GitHub:

```bash
sudo git clone https://github.com/bonsaibauer/enshrouded_server_docker.git
cd enshrouded_server_docker
```

## Step 2: Build the Docker image

Run the following command in the project directory:

```bash
docker build -t enshrouded-server .
```

## Step 3: Run the server with environment variables

```bash
docker run -d \
  --name enshroudedserver \
  --restart=always \
  -p 15637:15637/udp \
  -v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded \
  -e ENSHROUDED_SERVER_NAME="myservername" \
  -e ENSHROUDED_SERVER_MAXPLAYERS=16 \
  -e ENSHROUDED_VOICE_CHAT_MODE="Proximity" \
  -e ENSHROUDED_ENABLE_VOICE_CHAT=false \
  -e ENSHROUDED_ENABLE_TEXT_CHAT=false \
  -e ENSHROUDED_GAME_PRESET="Default" \
  -e ENSHROUDED_ADMIN_PW="AdminXXXXXXXX" \
  -e ENSHROUDED_FRIEND_PW="FriendXXXXXXXX" \
  -e ENSHROUDED_GUEST_PW="GuestXXXXXXXX" \
  enshrouded-server
```

### Explanation of the environment variables

> - `-d`: Run in detached mode (in the background).
> - `--name enshroudedserver`: Names the container "enshroudedserver".
> - `--restart=always`: Automatically restarts the container if it stops or the host reboots.
> - `-p 15637:15637/udp`: Maps the UDP port 15637 from the container to the host, required for the game server.
> - `-v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded`: Mounts a local directory for persistent data and configuration.
> - `-e ENSHROUDED_SERVER_NAME="myservername"`: Sets the server's visible name.
> - `-e ENSHROUDED_SERVER_MAXPLAYERS=16`: Limits the number of players to 16.
> - `-e ENSHROUDED_VOICE_CHAT_MODE="Proximity"`: Enables proximity-based voice chat.
> - `-e ENSHROUDED_ENABLE_VOICE_CHAT=false`: Disables voice chat (this overrides the mode setting).
> - `-e ENSHROUDED_ENABLE_TEXT_CHAT=false`: Disables text chat in-game.
> - `-e ENSHROUDED_GAME_PRESET="Default"`: Sets the game rules preset.
> - `-e ENSHROUDED_ADMIN_PW="AdminXXXXXXXX"`: Password for admin access.
> - `-e ENSHROUDED_FRIEND_PW="FriendXXXXXXXX"`: Password for friends to join.
> - `-e ENSHROUDED_GUEST_PW="GuestXXXXXXXX"`: Password for guest access.
> - `enshrouded-server`: The Docker image used to run the server.
>
> ?? **Tip:** You can skip the `-e` environment variables if you prefer to manage all server settings later in the `enshrouded_server.json` file inside the mounted volume.

## Monitor the server logs

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

---

Return to README: [Go to "4. Edit server configuration"](../README.md#4-edit-server-configuration)

