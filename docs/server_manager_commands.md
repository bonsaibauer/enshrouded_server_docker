# Server Manager Commands

Current commands according to `server_manager/entrypoints/ctl`.

Replace `enshroudedserver` with your container name (see `docker ps`).

## Direct via docker exec

```bash
docker exec enshroudedserver status
docker exec -it enshroudedserver menu
docker exec enshroudedserver start
docker exec enshroudedserver stop
docker exec enshroudedserver restart
docker exec enshroudedserver update
docker exec enshroudedserver backup
docker exec enshroudedserver password-view
docker exec enshroudedserver scheduled-restart
docker exec enshroudedserver force-update
docker exec enshroudedserver profile-reset
docker exec enshroudedserver enshrouded-profile-reset
docker exec enshroudedserver bootstrap
docker exec enshroudedserver cron-start
docker exec enshroudedserver cron-stop
docker exec enshroudedserver cron-restart
```

## Alternative via ctl

```bash
docker exec enshroudedserver ctl status
docker exec -it enshroudedserver ctl menu
docker exec enshroudedserver ctl start
docker exec enshroudedserver ctl stop
docker exec enshroudedserver ctl restart
docker exec enshroudedserver ctl update
docker exec enshroudedserver ctl backup
docker exec enshroudedserver ctl password-view
docker exec enshroudedserver ctl scheduled-restart
docker exec enshroudedserver ctl force-update
docker exec enshroudedserver ctl profile-reset
docker exec enshroudedserver ctl enshrouded-profile-reset
docker exec enshroudedserver ctl bootstrap
docker exec enshroudedserver ctl cron-start
docker exec enshroudedserver ctl cron-stop
docker exec enshroudedserver ctl cron-restart
```

## Supervisor Program Names

```text
enshrouded-bootstrap
enshrouded-server
enshrouded-updater
enshrouded-backup
enshrouded-restart
enshrouded-force-update
profile-reset
enshrouded-profile-reset
crond
```

## backup

`backup` triggers the Supervisor program `enshrouded-backup` and creates a zip backup of the latest savegame.

- Output folder: `BACKUP_DIR` (default: `/home/enshrouded/server/backups`)
- Filename pattern: `YYYY-MM-DD_HH-MM-SS-$SAVEFILE_NAME.zip`
- Retention: `BACKUP_MAX_COUNT` keeps the newest N zip backups (manual, cron, and safety backups all count toward the same limit)

Note: The interactive menu creates separate config backups (`enshrouded_server.json` / `server_manager.json`) under `BACKUP_DIR/profiles` when saving/applying settings.

## password-view

Shows `userGroups` (permissions + password) from the active `enshrouded_server.json`.

```bash
docker exec enshroudedserver password-view
```
