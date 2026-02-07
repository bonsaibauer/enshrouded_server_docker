# Server Manager Commands

This file collects the most important commands for the Docker container and the `server_manager`.

**Path inside the container**
`/opt/enshrouded/manager/manager.sh`

**Important**
All `manager.sh` commands can be run either inside the container or via `docker exec`.

**Docker Container Commands**
```bash
# Start the container (example from the README)
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -v /home/enshrouded/server_1:/home/steam/enshrouded \
  bonsaibauer/enshrouded_server_docker:dev_latest

# Manage the container
docker start enshroudedserver
docker stop enshroudedserver
docker restart enshroudedserver
docker logs -f enshroudedserver

# Enter the container
docker exec -it enshroudedserver bash

# Check/set restart policy
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' enshroudedserver
docker update --restart unless-stopped enshroudedserver
```

**Server Manager Commands (via docker exec)**
```bash
docker exec enshroudedserver manager.sh status
docker exec enshroudedserver manager.sh start
docker exec enshroudedserver manager.sh stop
docker exec enshroudedserver manager.sh restart
docker exec enshroudedserver manager.sh update
docker exec enshroudedserver manager.sh backup
docker exec enshroudedserver manager.sh logs
docker exec enshroudedserver manager.sh healthcheck
docker exec enshroudedserver manager.sh help
```

**Server Manager Commands (inside the container)**
```bash
/opt/enshrouded/manager/manager.sh status
/opt/enshrouded/manager/manager.sh start
/opt/enshrouded/manager/manager.sh stop
/opt/enshrouded/manager/manager.sh restart
/opt/enshrouded/manager/manager.sh update
/opt/enshrouded/manager/manager.sh backup
/opt/enshrouded/manager/manager.sh logs
/opt/enshrouded/manager/manager.sh healthcheck
/opt/enshrouded/manager/manager.sh help
```

**Supervisor (Status/Manual Control)**
```bash
supervisorctl -c /opt/enshrouded/manager/supervisord.conf status
supervisorctl -c /opt/enshrouded/manager/supervisord.conf start server-manager
supervisorctl -c /opt/enshrouded/manager/supervisord.conf stop server-manager
```

**Supervisor Programs (Names)**
- `server-manager-daemon` (Server Manager process)
- `server-manager` (Enshrouded server process)
- `server-manager-update`
- `server-manager-backup`
- `server-manager-restart`
- `server-manager-syslog`
- `server-manager-cron`
- `server-manager-logstream`
- `server-manager-supervisor-logstream`
- `server-manager-syslog-logstream`

**Cron/Automation**
The following env vars control schedules:
- `ENABLE_CRON` (`true/false`)
- `UPDATE_CRON`
- `BACKUP_CRON`
- `RESTART_CRON`

Auto-update and safe checks:
- `AUTO_UPDATE`
- `AUTO_UPDATE_INTERVAL`
