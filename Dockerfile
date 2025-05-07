# --------------------------
# Base Image
# --------------------------
FROM ubuntu:22.04

# --------------------------
# General Environment Variables
# --------------------------
ENV DEBIAN_FRONTEND "noninteractive"
ENV WINEARCH "win64"

# --------------------------
# Enshrouded Server Configuration
# --------------------------
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

# --------------------------
# Install Essential Packages
# --------------------------
RUN set -x \
&& apt update \
&& apt install -y \
    vim \
    wget \
    software-properties-common

# --------------------------
# Install SteamCMD and Dependencies
# --------------------------
RUN add-apt-repository -y multiverse \
&& dpkg --add-architecture i386 \
&& apt update \
&& echo steam steam/question select "I AGREE" | debconf-set-selections && echo steam steam/license note '' | debconf-set-selections \
&& apt install -y \
    lib32z1 \
    lib32gcc-s1 \
    lib32stdc++6 \
    steamcmd \
&& groupadd steam \
&& useradd -m steam -g steam \
&& passwd -d steam \
&& chown -R steam:steam /usr/games \
&& ln -s /usr/games/steamcmd /home/steam/steamcmd


# --------------------------
# Install Wine and Winetricks
# --------------------------
RUN dpkg --add-architecture amd64 \
&& mkdir -pm755 /etc/apt/keyrings \
&& wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
&& wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources \
&& apt update \
&& apt install -y --install-recommends \
    winehq-staging \
&& apt install -y --allow-unauthenticated \
    cabextract \
    winbind \
    screen

# --------------------------
# Create Server Directories
# --------------------------
RUN mkdir /home/steam/enshrouded \
&& mkdir /home/steam/enshrouded/savegame \
&& mkdir /home/steam/enshrouded/logs \
&& chown -R steam:steam /home/steam

# --------------------------
# Add Entrypoint Script
# --------------------------
ADD ./entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# --------------------------
# Prepare SteamCMD Environment
# --------------------------
USER steam
RUN /home/steam/steamcmd +quit
WORKDIR /home/steam

# --------------------------
# Volume and Port Configuration
# --------------------------
VOLUME /home/steam/enshrouded
EXPOSE 15637

# --------------------------
# Default Entrypoint
# --------------------------
ENTRYPOINT [ "/home/steam/entrypoint.sh" ]
