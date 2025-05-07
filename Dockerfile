######## Enshrouded Dedicated Server - SteamCMD & Wine ########

# Base image: Ubuntu 22.04 for WineHQ-Staging compatibility
FROM ubuntu:22.04

# Use bash with pipefail for safety in scripts
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# General environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'
ENV WINEARCH=win64
ENV HOME=/home/steam

# Enshrouded-specific server environment variables
ENV ENSHROUDED_SERVER_NAME="Enshrouded Server"
ENV ENSHROUDED_SERVER_MAXPLAYERS=16
ENV ENSHROUDED_SERVER_IP="0.0.0.0"
ENV ENSHROUDED_VOICE_CHAT_MODE="Proximity"
ENV ENSHROUDED_ENABLE_VOICE_CHAT=false
ENV ENSHROUDED_ENABLE_TEXT_CHAT=false
ENV ENSHROUDED_GAME_PRESET="Default"
ENV ENSHROUDED_ADMIN_PW="AdminXXXXXXXX"
ENV ENSHROUDED_FRIEND_PW="FriendXXXXXXXX"
ENV ENSHROUDED_GUEST_PW="GuestXXXXXXXX"

# Enable i386 architecture for 32-bit compatibility
RUN dpkg --add-architecture i386 && apt update

# Accept Steam EULA automatically
RUN echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections

# Install necessary packages
RUN apt install -y --no-install-recommends \
    locales \
    ca-certificates \
    software-properties-common \
    wget \
    vim \
    cabextract \
    winbind \
    screen \
    lib32z1 \
    lib32gcc-s1 \
    lib32stdc++6 \
    steamcmd

# Generate locale
RUN locale-gen en_US.UTF-8

# Create a non-root steam user
RUN groupadd steam && useradd -m steam -g steam && passwd -d steam && \
    chown -R steam:steam /usr/games

# Link SteamCMD into user home directory
RUN ln -s /usr/games/steamcmd /home/steam/steamcmd

# Install WineHQ-Staging from official repository
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt update && \
    apt install -y --install-recommends winehq-staging

# Prepare Enshrouded directories
RUN mkdir -p /home/steam/enshrouded/savegame /home/steam/enshrouded/logs && \
    chown -R steam:steam /home/steam

# Add entrypoint script
ADD ./entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# Switch to steam user
USER steam
WORKDIR /home/steam

# Run SteamCMD once to initialize
RUN /home/steam/steamcmd +quit

# Set up symlinks for Steam client libraries required by Wine
RUN mkdir -p $HOME/.steam && \
    ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32 && \
    ln -s $HOME/.local/share/Steam/steamcmd/linux64 $HOME/.steam/sdk64 && \
    ln -s $HOME/.steam/sdk32/steamclient.so $HOME/.steam/sdk32/steamservice.so && \
    ln -s $HOME/.steam/sdk64/steamclient.so $HOME/.steam/sdk64/steamservice.so

# Declare volume for persistent save data
VOLUME /home/steam/enshrouded

# Expose network ports used by Enshrouded
EXPOSE 15636 15637

# Run the entrypoint script
ENTRYPOINT ["/home/steam/entrypoint.sh"]
