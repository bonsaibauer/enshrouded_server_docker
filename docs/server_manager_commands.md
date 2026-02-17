# Server Manager Commands

Current commands according to `server_manager/jobs/cmd`.

Replace `enshroudedserver` with your container name (see `docker ps`).

## General Form

```bash
docker exec enshroudedserver cmd <command> [args...]
```

## Common Commands

```bash
docker exec enshroudedserver cmd status
docker exec -it enshroudedserver cmd menu
docker exec enshroudedserver cmd start
docker exec enshroudedserver cmd stop
docker exec enshroudedserver cmd restart
docker exec enshroudedserver cmd update
docker exec enshroudedserver cmd password-view
docker exec enshroudedserver cmd bootstrap
docker exec enshroudedserver cmd scheduled-restart
docker exec enshroudedserver cmd force-update
docker exec enshroudedserver cmd cron-start
docker exec enshroudedserver cmd cron-stop
docker exec enshroudedserver cmd cron-restart
```

## Commands With Required Args

```bash
# full/manual backup example
docker exec enshroudedserver cmd backup --mode manual --savegame true --enshrouded-config true --manager-config true --cleanup false

# config-only backup example
docker exec enshroudedserver cmd backup --mode manual --savegame false --enshrouded-config true --manager-config true --cleanup false

# restore example
docker exec enshroudedserver cmd restore-backup --zip /home/enshrouded/server/backups/manual/<file>.zip --restore all --safety-backup false

# profile apply/reset examples
docker exec enshroudedserver cmd profile --target enshrouded --action apply --profile default --create-backup true
docker exec enshroudedserver cmd profile --target manager --action reset --create-backup true

# env validation examples
docker exec enshroudedserver cmd env-validation verify
docker exec enshroudedserver cmd env-validation init-runtime
docker exec enshroudedserver cmd env-validation check ENSHROUDED_SLOT_COUNT 16
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
