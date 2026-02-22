# Enshrouded Dedicated Server - Docker Hub Notes

## Documentation

- Environment variables: `docs/environment.md`
- Profiles: `docs/profile.md`
- Commands: `docs/server_manager_commands.md`
- Logs: `docs/log.md`
- Changelog (init): `docs/changelog/v3.0.0.md`
- Dev branch logs (unofficial): `docs/changelog/dev-logs.md`

## Quickstart

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:${ENSHROUDED_QUERY_PORT:=15637}/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e ENSHROUDED_QUERY_PORT \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:latest
```

## Commands

```bash
docker exec enshroudedserver status
docker exec -it enshroudedserver menu
docker exec enshroudedserver start
docker exec enshroudedserver stop
docker exec enshroudedserver restart
docker exec enshroudedserver update
docker exec enshroudedserver update force
docker exec enshroudedserver backup
docker exec enshroudedserver backup list
docker exec enshroudedserver backup restore <file>.zip all
docker exec enshroudedserver profile enshrouded apply default
docker exec enshroudedserver password-view
docker exec enshroudedserver env-validation verify
docker exec enshroudedserver scheduled-restart
docker exec enshroudedserver bootstrap
docker exec enshroudedserver cron sync
docker exec enshroudedserver cron restart
```
