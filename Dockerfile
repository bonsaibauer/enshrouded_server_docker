# Use a base Ubuntu image
FROM steamcmd/steamcmd:ubuntu-24@sha256:7b54eb6c3abf01d11b9fc78383bcd4dd3a613104997d476ad3203f52e58b7bbb

LABEL maintainer="bonsaibauer"

# Environment variables for SteamCMD
ENV STEAMCMDDIR="/home/enshrouded/steamcmd"
ENV SERVERDIR="/home/enshrouded/enshroudedserver"
ARG WINE_BRANCH=stable

# Set DEBIAN_FRONTEND to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        cabextract \
        winbind \
        xvfb \
        software-properties-common \
        lsb-release && \
    dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    curl -o /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    curl -O --output-dir /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)/winehq-$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2).sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-${WINE_BRANCH} && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create the user 'enshrouded'
RUN groupadd -g 1000 enshrouded && useradd -m -u 1000 -g enshrouded enshrouded

# Switch to the enshrouded user to isolate server installation from root
USER enshrouded
WORKDIR /home/enshrouded

# Create necessary directories
RUN mkdir -p ${STEAMCMDDIR} ${SERVERDIR}

# Install the server via SteamCMD
RUN steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir ${SERVERDIR} +login anonymous +app_update 2278520 validate +quit

# Copy server config (optional)
COPY --chown=enshrouded:enshrouded enshrouded_server.json ${SERVERDIR}/enshrouded_server.json

# Expose ports
EXPOSE 15636/tcp
EXPOSE 15637/tcp

# Start the Windows server executable via Wine
ENTRYPOINT ["wine", "/home/enshrouded/enshroudedserver/enshrouded_server.exe"]

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=dialog
