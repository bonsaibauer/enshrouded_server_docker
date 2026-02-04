# --------------------------
# Base Image
# --------------------------
FROM steamcmd/steamcmd:ubuntu-24@sha256:87c49169a229ec426fa35e3fcae7e8ff274b67e56d950a15e289820f3a114ea3

# --------------------------
# General Environment Variables
# --------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV WINEARCH=win64

# --------------------------
# Minimal Base Packages (tini for signal handling, locales for UTF-8)
# --------------------------
RUN set -x \
 && dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      tini \
      locales \
      wget \
      ca-certificates \
      cabextract \
      winbind \
      screen \
      lib32z1 \
      lib32gcc-s1 \
      lib32stdc++6 \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# --------------------------
# Install Wine (stable by default) from winehq repo
# --------------------------
ARG WINE_BRANCH=stable
RUN set -x \
 && mkdir -pm755 /etc/apt/keyrings \
 && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
 && . /etc/os-release \
 && wget -O /etc/apt/sources.list.d/winehq.sources \
      https://dl.winehq.org/wine-builds/ubuntu/dists/$VERSION_CODENAME/winehq-$VERSION_CODENAME.sources \
 && apt-get update \
 && apt-get install -y --install-recommends winehq-${WINE_BRANCH} \
 && ln -s /opt/wine-${WINE_BRANCH}/bin/* /usr/local/bin/ \
# Ensure no stray Go toolchain (source of prior CVEs)
 && apt-get purge -y golang-* python3-cryptography || true \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /usr/local/go /usr/lib/go-1.* /usr/lib/go /usr/share/go /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------
# Create required directories
# --------------------------
RUN set -x \
 && mkdir -p /home/steam/.steam \
 && mkdir -p /home/steam/enshrouded/savegame \
 && mkdir -p /home/steam/enshrouded/logs \
 && ln -s /usr/games/steamcmd /home/steam/steamcmd \
 && chown -R steam:steam /home/steam

# --------------------------
# Add Entrypoint
# --------------------------
ADD ./entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

USER steam
WORKDIR /home/steam

# --------------------------
# Volume and Port Configuration
# --------------------------
VOLUME /home/steam/enshrouded
EXPOSE 15637/udp

# --------------------------
# Default Entrypoint
# --------------------------
ENTRYPOINT ["/usr/bin/tini", "--", "/home/steam/entrypoint.sh"]
