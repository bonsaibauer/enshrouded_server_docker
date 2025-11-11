# Option (B) Launch the Container (Simplified Version)

You can launch the Enshrouded server container with just the essential Docker options.
Since all configuration can be handled later through the `enshrouded_server.json` file,
there's no need to set environment variables during startup.

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

## Step 3: Run the server

```bash
docker run -d \
  --name enshroudedserver \
  --restart=always \
  -p 15637:15637/udp \
  -v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded \
  enshrouded-server
```

### Explanation of the command

> - `-d`: Runs the container in detached mode (in the background).
> - `--name enshroudedserver`: Names the container so you can reference it easily.
> - `--restart=always`: Ensures the container automatically restarts if the server or host restarts.
> - `-p 15637:15637/udp`: Exposes the necessary UDP port for the game.
> - `-v /home/enshrouded/enshrouded_server_docker:/home/steam/enshrouded`: Mounts a local directory for persistent data like the configuration file (`enshrouded_server.json`).
> - `enshrouded-server`: The name of the Docker image you're using to run the server.
>
> Once the container is running, you can stop it, edit the `enshrouded_server.json` file in the mounted volume (`/home/enshrouded/enshrouded_server_docker`), and then start the container again.

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

