FROM steamcmd/steamcmd:ubuntu-24@sha256:87c49169a229ec426fa35e3fcae7e8ff274b67e56d950a15e289820f3a114ea3 AS builder

ARG GE_PROTON_VERSION="10-28"

# Install prerequisites
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        curl \
        tar \
        dbus \
    && apt autoremove --purge && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install proton
RUN curl -sLOJ "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${GE_PROTON_VERSION}/GE-Proton${GE_PROTON_VERSION}.tar.gz" \
    && mkdir -p /tmp/proton \
    && tar -xzf GE-Proton*.tar.gz -C /tmp/proton --strip-components=1 \
    && rm GE-Proton*.* \
    && rm -f /etc/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id


FROM steamcmd/steamcmd:ubuntu-24@sha256:87c49169a229ec426fa35e3fcae7e8ff274b67e56d950a15e289820f3a114ea3

# Install dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        curl \
        supervisor \
        cron \
        rsyslog \
        jq \
        zip \
        python3 \
        python3-pip \
        libfreetype6 \
        libfreetype6:i386 \
    && apt autoremove --purge && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install winetricks (unused)
RUN curl -o /tmp/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /tmp/winetricks && install -m 755 /tmp/winetricks /usr/local/bin/winetricks \
    && rm -rf /tmp/*

# MISC
RUN mkdir -p /usr/local/etc /var/log/supervisor /var/run/enshrouded /usr/local/etc/supervisor/conf.d/ /home/enshrouded/.steam/sdk32 /home/enshrouded/.steam/sdk64 /home/enshrouded/.config/protonfixes /home/enshrouded/.cache/protonfixes \
    && groupadd -g "${PGID:-4711}" -o enshrouded \
    && useradd -g "${PGID:-4711}" -u "${PUID:-4711}" -o --create-home enshrouded \
    && ln -f /root/.steam/sdk32/steamclient.so /home/enshrouded/.steam/sdk32/steamclient.so \
    && ln -f /root/.steam/sdk64/steamclient.so /home/enshrouded/.steam/sdk64/steamclient.so \
    && sed -i '/imklog/s/^/#/' /etc/rsyslog.conf \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /tmp/proton /usr/local/bin
COPY --from=builder /etc/machine-id /etc/machine-id

COPY ./server_manager/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chmod=755 ./server_manager/jobs/ /usr/local/etc/enshrouded/jobs/
COPY --chmod=755 ./server_manager/env/ /usr/local/etc/enshrouded/env/
COPY ./server_manager/profiles/ /usr/local/etc/enshrouded/profiles/
RUN ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/server \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/hook-run \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/guard-run \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/guard-require \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/menu \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/status \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/start \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/stop \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/restart \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/update \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/backup \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/backup-config \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/profile \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/password-view \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/env-validation \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/scheduled-backup \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/scheduled-restart \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/force-update \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/bootstrap \
    && ln -sf /usr/local/etc/enshrouded/jobs/server /usr/local/bin/cron
RUN find /usr/local/etc/enshrouded -type f -exec sed -i 's/\r$//' {} +

WORKDIR /usr/local/etc/enshrouded
CMD ["/usr/local/etc/enshrouded/jobs/bootstrap", "--entrypoint"]
ENTRYPOINT []
