# Server Manager Commands

Current commands are dispatched centrally by `server_manager/jobs/server`.

Replace `enshroudedserver` with your container name (see `docker ps`).

## General Form

```bash
docker exec enshroudedserver server <command> [args...]
```

## Common Commands

```bash
docker exec enshroudedserver server status
docker exec -it enshroudedserver server menu
docker exec enshroudedserver server start
docker exec enshroudedserver server stop
docker exec enshroudedserver server restart
docker exec enshroudedserver server update
docker exec enshroudedserver server password-view
docker exec enshroudedserver server profile --password-view --format json
docker exec enshroudedserver server bootstrap
docker exec enshroudedserver server cron
docker exec enshroudedserver server scheduled-restart
docker exec enshroudedserver server force-update
```

## Commands With Required Args

```bash
# full/manual backup example
docker exec enshroudedserver server backup --mode manual --savegame true --enshrouded-config true --manager-config true --cleanup false

# config-only backup example
docker exec enshroudedserver server backup --mode manual --savegame false --enshrouded-config true --manager-config true --cleanup false

# restore example
docker exec enshroudedserver server restore-backup --zip /home/enshrouded/server/backups/manual/<file>.zip --restore all --safety-backup false

# profile apply/reset examples
docker exec enshroudedserver server profile --target enshrouded --action apply --profile default --create-backup true
docker exec enshroudedserver server profile --target manager --action reset --create-backup true

# env validation examples
docker exec enshroudedserver server env-validation verify
docker exec enshroudedserver server env-validation init-runtime
docker exec enshroudedserver server env-validation check ENSHROUDED_SLOT_COUNT 16

# cron sync examples
docker exec enshroudedserver server cron --sync
docker exec enshroudedserver server cron --sync --update-cron "0 */6 * * *" --backup-cron "0 3 * * *" --restart-cron "0 5 * * *"
docker exec enshroudedserver server cron --service restart
```

## Supervisor Program Names (internal)

```text
bootstrap
server
updater
backup
restart
password-view
profile
restore-backup
env-validation
crond
```

## Notes

- `profile` and `restore-backup` are arg-driven jobs.
- `env-validation` uses subcommands: `verify`, `init-runtime`, `check`.
