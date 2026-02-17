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
  -e EN_PROFILE="default" \
  -e MANAGER_PROFILE="default" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:latest
```

## Commands

```bash
docker exec enshroudedserver cmd status
docker exec -it enshroudedserver cmd menu
docker exec enshroudedserver cmd start
docker exec enshroudedserver cmd stop
docker exec enshroudedserver cmd restart
docker exec enshroudedserver cmd update
docker exec enshroudedserver cmd backup --mode manual --savegame true --enshrouded-config true --manager-config true --cleanup false
docker exec enshroudedserver cmd restore-backup --zip /home/enshrouded/server/backups/manual/<file>.zip --restore all --safety-backup false
docker exec enshroudedserver cmd profile --target enshrouded --action apply --profile default --create-backup true
docker exec enshroudedserver cmd password-view
docker exec enshroudedserver cmd env-validation verify
docker exec enshroudedserver cmd scheduled-restart
docker exec enshroudedserver cmd force-update
docker exec enshroudedserver cmd bootstrap
docker exec enshroudedserver cmd cron --sync
docker exec enshroudedserver cmd cron --service restart
```
