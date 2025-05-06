# Use a base Ubuntu image
FROM ubuntu:24.04

# Environment variables for SteamCMD
ENV STEAMCMDDIR="/usr/games"
ENV SERVERDIR="/home/enshrouded/enshroudedserver"

# Set DEBIAN_FRONTEND to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install dependencies
RUN apt update && \
    apt upgrade -y && \
    apt install -y software-properties-common lsb-release wget ufw cabextract winbind screen xvfb && \

    # Add i386 architecture support (needed by SteamCMD and Wine)
    dpkg --add-architecture i386 && \
    
    # Prepare Wine repository
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources && \
    
    # Install Wine (staging version)
    apt update && \
    apt install -y --install-recommends winehq-staging && \
    
    # Add multiverse repository (some SteamCMD or Wine dependencies are in multiverse)
    apt install -y software-properties-common && \
    add-apt-repository multiverse && \
    apt update && \
    
    # Automatically accept Steam license agreement during install
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    
    # Install SteamCMD
    apt install -y steamcmd && \
    
    # Clean up APT cache to reduce image size
    apt clean

# Create the user 'enshrouded'
RUN useradd -m enshrouded

# Switch to the enshrouded user to isolate server installation from root
USER enshrouded
WORKDIR /home/enshrouded

# Use SteamCMD to download and install the game server
RUN ${STEAMCMDDIR}/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir ${SERVERDIR} +login anonymous +app_update 2278520 validate +quit

# Add custom server configuration (replace this with your own JSON config if needed)
COPY --chown=enshrouded:enshrouded enshrouded_server.json ${SERVERDIR}/enshrouded_server.json

# Expose required TCP ports for server communication
EXPOSE 15636/tcp
EXPOSE 15637/tcp

# Start the game server with Wine (since the server is a Windows executable)
ENTRYPOINT ["wine", "/home/enshrouded/enshroudedserver/enshrouded_server.exe"]

# Reset DEBIAN_FRONTEND to its default state
ENV DEBIAN_FRONTEND=dialog
