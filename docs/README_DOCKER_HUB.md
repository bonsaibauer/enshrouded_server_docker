# Enshrouded Dedicated Server – Docker Hub Notes

## Dokumentation

- ENV-Variablen: `docs/environment.md`
- Profile: `docs/profile.md`
- Commands: `docs/server_manager_commands.md`
- Logs: `docs/log.md`
- Changelog (Init): `docs/changelog/v3.0.0.md`

## Quickstart

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="default" \
  -e MANAGER_PROFILE="default" \
  -e LOG_COLOR="true" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  -v /home/enshrouded/server_1/server_manager:/server_manager \
  -v /home/enshrouded/server_1/profile:/profile \
  bonsaibauer/enshrouded_server_docker:latest
```

## Commands

```bash
docker exec enshroudedserver status
docker exec enshroudedserver start
docker exec enshroudedserver stop
docker exec enshroudedserver restart
docker exec enshroudedserver update
docker exec enshroudedserver backup
docker exec enshroudedserver scheduled-restart
docker exec enshroudedserver force-update
docker exec enshroudedserver profile-reset
docker exec enshroudedserver enshrouded-profile-reset
docker exec enshroudedserver bootstrap
docker exec enshroudedserver cron-start
docker exec enshroudedserver cron-stop
docker exec enshroudedserver cron-restart
```
