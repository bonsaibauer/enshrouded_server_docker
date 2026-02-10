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
docker exec enshroudedserver enshrouded-backup-config
docker exec enshroudedserver server-manager-backup-config
docker exec enshroudedserver server-manager-profil-apply
docker exec enshroudedserver enshrouded-profile-apply
docker exec enshroudedserver enshrouded-config-restore
docker exec enshroudedserver server-manager-config-restore
docker exec enshroudedserver enshrouded-backup-restore
docker exec enshroudedserver password-view
docker exec enshroudedserver scheduled-restart
docker exec enshroudedserver force-update
docker exec enshroudedserver server-manager-profil-reset
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
docker exec enshroudedserver ctl enshrouded-backup-config
docker exec enshroudedserver ctl server-manager-backup-config
docker exec enshroudedserver ctl server-manager-profil-apply
docker exec enshroudedserver ctl enshrouded-profile-apply
docker exec enshroudedserver ctl enshrouded-config-restore
docker exec enshroudedserver ctl server-manager-config-restore
docker exec enshroudedserver ctl enshrouded-backup-restore
docker exec enshroudedserver ctl password-view
docker exec enshroudedserver ctl scheduled-restart
docker exec enshroudedserver ctl force-update
docker exec enshroudedserver ctl server-manager-profil-reset
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
enshrouded-backup-config
server-manager-backup-config
enshrouded-restart
enshrouded-force-update
server-manager-profil-reset
enshrouded-profile-reset
crond
enshrouded-password-view
enshrouded-profile-apply
server-manager-profil-apply
enshrouded-config-restore
server-manager-config-restore
enshrouded-backup-restore
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

## restore/apply jobs (menu-driven)

The interactive menu uses request files in the persistent volume and then starts Supervisor jobs:

- `server-manager-profil-apply`
- `enshrouded-profile-apply`
- `enshrouded-config-restore`
- `server-manager-config-restore`
- `enshrouded-backup-restore`

These jobs are intended to be triggered by the menu (which writes the request JSON first). When triggered, output is logged via Supervisor and visible in `docker logs`.
