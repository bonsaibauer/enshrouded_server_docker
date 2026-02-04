# --------------------------
# Base Image
# --------------------------
FROM docker.io/library/ubuntu:24.04

# --------------------------
# General Environment Variables
# --------------------------
ENV DEBIAN_FRONTEND="noninteractive"
ENV WINEARCH="win64"

# --------------------------
# Install Essential Packages (minimal, no recommends)
# --------------------------
RUN set -x \
&& apt update \
&& apt install -y --no-install-recommends \
    vim \
    wget \
    locales \
    tini \
&& locale-gen en_US.UTF-8 \
&& update-locale LANG=en_US.UTF-8 \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# --------------------------
# Install SteamCMD and Dependencies
# --------------------------
RUN set -x \
&& apt update \
&& apt install -y --no-install-recommends software-properties-common \
&& add-apt-repository -y multiverse \
&& dpkg --add-architecture i386 \
&& apt update \
&& echo steam steam/question select "I AGREE" | debconf-set-selections && echo steam steam/license note '' | debconf-set-selections \
&& apt install -y --no-install-recommends \
    lib32z1 \
    lib32gcc-s1 \
    lib32stdc++6 \
    steamcmd \
&& groupadd steam \
&& useradd -m steam -g steam \
&& passwd -d steam \
&& chown -R steam:steam /usr/games \
&& ln -s /usr/games/steamcmd /home/steam/steamcmd \
&& apt purge -y software-properties-common python3-cryptography golang-* \
&& apt autoremove -y \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------
# Install Wine and Winetricks (add repo without software-properties-common)
# --------------------------
RUN set -x \
&& dpkg --add-architecture amd64 \
&& mkdir -pm755 /etc/apt/keyrings \
&& wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
&& . /etc/os-release \
&& wget -O /etc/apt/sources.list.d/winehq.sources \
     https://dl.winehq.org/wine-builds/ubuntu/dists/$VERSION_CODENAME/winehq-$VERSION_CODENAME.sources \
&& apt update \
&& apt install -y --install-recommends \
    winehq-staging \
&& apt install -y --no-install-recommends \
    cabextract \
    winbind \
    screen \
&& apt purge -y python3-cryptography golang-* \
&& apt autoremove -y \
&& apt-get clean \
&& rm -rf /usr/local/go /usr/lib/go-1.* /usr/lib/go /usr/share/go /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------
# Create Server Directories
# --------------------------
RUN mkdir -p /home/steam/.steam \
&& mkdir -p /home/steam/enshrouded \
&& mkdir -p /home/steam/enshrouded/savegame \
&& mkdir -p /home/steam/enshrouded/logs \
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
EXPOSE 15637/udp

# --------------------------
# Default Entrypoint
# --------------------------
ENTRYPOINT [ "/usr/bin/tini", "--", "/home/steam/entrypoint.sh" ]
