# --------------------------
# Build Args
# --------------------------
ARG BASE_IMAGE="docker.io/library/ubuntu:24.04"
ARG STEAMCMD_IMAGE="steamcmd/steamcmd:ubuntu-24@sha256:87c49169a229ec426fa35e3fcae7e8ff274b67e56d950a15e289820f3a114ea3"
ARG PROTON_VER="10-28"

# --------------------------
# Proton Builder
# --------------------------
FROM ${STEAMCMD_IMAGE} AS proton-builder
ARG PROTON_VER

RUN dpkg --add-architecture i386 \
&& apt-get update \
&& DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    curl \
    tar \
    dbus \
&& apt-get autoremove --purge -y && apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sLOJ "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${PROTON_VER}/GE-Proton${PROTON_VER}.tar.gz" \
&& mkdir -p /tmp/proton \
&& tar -xzf GE-Proton*.tar.gz -C /tmp/proton --strip-components=1 \
&& rm GE-Proton*.* \
&& rm -f /etc/machine-id \
&& dbus-uuidgen --ensure=/etc/machine-id

# --------------------------
# Base Image
# --------------------------
FROM ${BASE_IMAGE}

# --------------------------
# Config (ENV defaults)
# --------------------------
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    STEAM_APP_ID="2278520"

# --------------------------
# Base Tools + Locale
# --------------------------
RUN set -x \
&& apt update \
&& apt upgrade -y \
&& apt install -y \
    curl \
    cron \
    rsyslog \
    supervisor \
    jq \
    procps \
    python3 \
    python3-pip \
    vim \
    wget \
    software-properties-common \
    locales \
    zip \
    tini \
&& locale-gen "${LANG}" \
&& update-locale LANG="${LANG}"

# --------------------------
# SteamCMD + Dependencies
# --------------------------
RUN add-apt-repository -y multiverse \
&& dpkg --add-architecture i386 \
&& apt update \
&& echo steam steam/question select "I AGREE" | debconf-set-selections && echo steam steam/license note '' | debconf-set-selections \
&& apt install -y \
    lib32z1 \
    lib32gcc-s1 \
    lib32stdc++6 \
    libfreetype6 \
    libfreetype6:i386 \
    steamcmd \
&& groupadd steam \
&& useradd -m steam -g steam \
&& passwd -d steam \
&& chown -R steam:steam /usr/games \
&& ln -s /usr/games/steamcmd /home/steam/steamcmd

# --------------------------
# GE-Proton (runtime)
# --------------------------
COPY --from=proton-builder /tmp/proton /usr/local/bin
COPY --from=proton-builder /etc/machine-id /etc/machine-id

# --------------------------
# Directories
# --------------------------
RUN mkdir -p "/home/steam/.steam" \
&& mkdir -p "/home/steam/enshrouded" \
&& mkdir -p "/home/steam/enshrouded/savegame" \
&& mkdir -p "/home/steam/enshrouded/logs" \
&& chown -R steam:steam "/home/steam"

# --------------------------
# Server Manager
# --------------------------
ADD ./server_manager /opt/enshrouded/manager
RUN chmod +x /opt/enshrouded/manager/manager.sh /opt/enshrouded/manager/lib/*.sh \
&& ln -sf /opt/enshrouded/manager/manager.sh /usr/local/bin/manager.sh

# --------------------------
# Prime SteamCMD
# --------------------------
USER steam
RUN /home/steam/steamcmd +quit
WORKDIR /home/steam

# --------------------------
# Runtime User (required for PUID/PGID mapping)
# --------------------------
USER root

# --------------------------
# Volume + Port
# --------------------------
VOLUME /home/steam/enshrouded
EXPOSE 15637/udp

# --------------------------
# Default Entrypoint
# --------------------------
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/enshrouded/manager/manager.sh", "run" ]
