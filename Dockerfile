######## Enshrouded Dedicated Server - SteamCMD & Wine ########

FROM ubuntu:22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# System-Umgebungsvariablen
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'
ENV WINEARCH=win64
ENV HOME=/home/steam
ENV XDG_RUNTIME_DIR=/tmp/runtime

# ==== Enshrouded Server Konfiguration mit Defaults ====
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

# 32-bit Architektur für Wine aktivieren und System vorbereiten
RUN dpkg --add-architecture i386 && apt update && apt install -y --no-install-recommends \
    locales \
    ca-certificates \
    software-properties-common \
    wget \
    curl \
    tar \
    vim \
    cabextract \
    winbind \
    screen \
    lib32z1 \
    lib32gcc-s1 \
    lib32stdc++6 \
    libvulkan1 \
    mesa-vulkan-drivers

# Locale setzen
RUN locale-gen en_US.UTF-8

# Benutzer 'steam' einrichten
RUN groupadd steam && useradd -m steam -g steam && passwd -d steam && \
    mkdir -p /tmp/runtime && chown -R steam:steam /tmp/runtime

# WineHQ-Staging installieren
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt update && \
    apt install -y --install-recommends winehq-staging

# SteamCMD manuell installieren
RUN mkdir -p /opt/steamcmd && \
    curl -sSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -xz -C /opt/steamcmd && \
    chmod +x /opt/steamcmd/steamcmd.sh && \
    chown -R steam:steam /opt/steamcmd && \
    ln -s /opt/steamcmd/steamcmd.sh /usr/bin/steamcmd


# Enshrouded-Verzeichnisse vorbereiten
RUN mkdir -p /home/steam/enshrouded/savegame /home/steam/enshrouded/logs && \
    chown -R steam:steam /home/steam

# Entrypoint hinzufügen
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# Benutzer wechseln
USER steam
WORKDIR /home/steam

# Volume für Spielstände und Konfiguration
VOLUME /home/steam/enshrouded

# Nur Query-Port (gamePort ist veraltet)
EXPOSE 15637/udp

# Serverstart
ENTRYPOINT ["/home/steam/entrypoint.sh"]

