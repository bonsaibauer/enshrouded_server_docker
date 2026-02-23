[![Made With Love](https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F-by%20bonsaibauer-green)](https://github.com/bonsaibauer)
[![Repository](https://img.shields.io/badge/Repository-enshrouded__server__docker-blue?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker)
![License](https://img.shields.io/badge/License-MIT-blue)
[![Docker Pulls](https://img.shields.io/docker/pulls/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
[![Docker Stars](https://img.shields.io/docker/stars/bonsaibauer/enshrouded_server_docker.svg?cacheSeconds=60)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/bonsaibauer/enshrouded_server_docker/latest)](https://hub.docker.com/r/bonsaibauer/enshrouded_server_docker)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=bonsaibauer.enshrouded_server_docker)
[![Report Problem](https://img.shields.io/badge/Report-new_Problem_or_Issue-critical?style=flat&logo=github)](https://github.com/bonsaibauer/enshrouded_server_docker/issues/new)

![GitHub Stars](https://img.shields.io/github/stars/bonsaibauer/enshrouded_server_docker?style=social)
![GitHub Forks](https://img.shields.io/github/forks/bonsaibauer/enshrouded_server_docker?style=social)

# Enshrouded Dedicated Server - Docker Hub Notes

## Documentation

- Repository: [bonsaibauer/enshrouded_server_docker](https://github.com/bonsaibauer/enshrouded_server_docker)
- `docs/commands.md`: [docs/commands.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/commands.md)
- `docs/enshrouded_server.md`: [docs/enshrouded_server.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/enshrouded_server.md)
- `docs/menu.md`: [docs/menu.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/menu.md)
- `docs/profile.md`: [docs/profile.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/profile.md)
- `docs/readme_docker_hub.md`: [docs/readme_docker_hub.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/readme_docker_hub.md)
- `docs/server_manager.md`: [docs/server_manager.md](https://github.com/bonsaibauer/enshrouded_server_docker/blob/main/docs/server_manager.md)

## Quickstart

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  --stop-timeout 90 \
  -p 15637:${ENSHROUDED_QUERY_PORT:=15637}/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="default" \
  -e MANAGER_PROFILE="default" \
  -e ENSHROUDED_QUERY_PORT \
  -e ENSHROUDED_NAME="My Enshrouded Server" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:dev_latest
```

> [!NOTE]
> `ENSHROUDED_QUERY_PORT` is `env_mode=deferred`: early startup validation can proceed when empty, but runtime still needs a resolved value (ENV or valid config/profile fallback). In menu editors this field is treated as hard ENV-managed (locked).

> [!TIP]
> 🎛️ Open the control center with: `docker exec -it enshroudedserver menu`

## Simple Docker Commands

- `docker logs -f enshroudedserver`: Follows recent container logs live.
- Manager runtime log file (including `supervisord` main log): `/home/enshrouded/server/logs/server_manager.log` (or `${ENSHROUDED_LOG_DIR}/server_manager.log`).
- On bootstrap, an existing `server_manager.log` is rotated to `/home/enshrouded/server/logs/server_manager_backup/server_manager_<timestamp>.log`.
- `docker start enshroudedserver`: Starts the existing container.
- `docker stop enshroudedserver`: Stops the container with a safe 90s grace period.
- `docker restart enshroudedserver`: Restarts the container with graceful shutdown behavior.
- `docker rm enshroudedserver`: Removes the stopped container.


## Simple Commands (Quick Readme)

- `docker exec enshroudedserver help`: Shows built-in command overview from the server dispatcher.
- `docker exec enshroudedserver status`: Shows supervisor status for all jobs (`server`, `updater`, `crond`, ...).
- `docker exec -it enshroudedserver menu`: Opens the interactive management menu.
- `docker exec enshroudedserver start`: Starts the server job.
- `docker exec enshroudedserver stop`: Stops the server job.
- `docker stop -t 90 enshroudedserver`: Stops the whole container with safe grace time.
- `docker exec enshroudedserver restart`: Runs the restart job with defaults from `server_manager.json`.
- `docker exec enshroudedserver update`: Runs normal updater flow (install if needed, then start server).
- `docker exec enshroudedserver update force`: Forces full update path.
- `docker exec enshroudedserver backup`: Creates a manual backup with default includes (savegame + both config files).
- `docker exec enshroudedserver backup list`: Lists available backup ZIP files (manual + scheduled).
- `docker exec enshroudedserver backup inspect <backup.zip>`: Shows which components are in a backup ZIP.
- `docker exec enshroudedserver backup restore <backup.zip> [savegame|enshrouded|manager|all]`: Restores selected parts (default target is `all`).
- `docker exec enshroudedserver profile <manager|enshrouded> <apply|reset> [profile]`: Applies/resets profile (with config backup).
- `docker exec enshroudedserver profile passwords [text|json]`: Alias for `password-view` with the same output formats.
- `docker exec enshroudedserver password-view`: Shows user group rights/passwords.
- `docker exec enshroudedserver cron sync`: Rewrites cron table from current `server_manager.json`.
- `docker exec enshroudedserver cron [start|stop|restart|status]`: Controls `crond` service.

## Buy Me A Coffee
If this project has helped you in any way, do buy me a coffee so I can continue to build more of such projects in the future and share them with the community!

<a href="https://buymeacoffee.com/bonsaibauer" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
