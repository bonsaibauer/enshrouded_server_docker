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
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:latest
```

## Commands

```bash
docker exec enshroudedserver server status
docker exec -it enshroudedserver server menu
docker exec enshroudedserver server start
docker exec enshroudedserver server stop
docker exec enshroudedserver server restart
docker exec enshroudedserver server update
docker exec enshroudedserver server backup --mode manual --savegame true --enshrouded-config true --manager-config true --cleanup false
docker exec enshroudedserver server restore-backup --zip /home/enshrouded/server/backups/manual/<file>.zip --restore all --safety-backup false
docker exec enshroudedserver server profile --target enshrouded --action apply --profile default --create-backup true
docker exec enshroudedserver server password-view
docker exec enshroudedserver server env-validation verify
docker exec enshroudedserver server scheduled-restart
docker exec enshroudedserver server force-update
docker exec enshroudedserver server bootstrap
docker exec enshroudedserver server cron --sync
docker exec enshroudedserver server cron --service restart
```
