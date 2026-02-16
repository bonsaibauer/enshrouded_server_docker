# Server Manager Commands

Current commands according to `server_manager/jobs/ctl`.

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
docker exec enshroudedserver backup-config
docker exec enshroudedserver restore-backup
docker exec enshroudedserver profile
docker exec enshroudedserver password-view
docker exec enshroudedserver scheduled-restart
docker exec enshroudedserver force-update
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
docker exec enshroudedserver ctl backup-config
docker exec enshroudedserver ctl restore-backup
docker exec enshroudedserver ctl profile
docker exec enshroudedserver ctl password-view
docker exec enshroudedserver ctl scheduled-restart
docker exec enshroudedserver ctl force-update
docker exec enshroudedserver ctl bootstrap
docker exec enshroudedserver ctl cron-start
docker exec enshroudedserver ctl cron-stop
docker exec enshroudedserver ctl cron-restart
```

## Supervisor Program Names

```text
bootstrap
server
updater
backup
restart
force-update
password-view
profile
restore-backup
crond
```

## Notes

- `backup` creates zip savegame backups in `BACKUP_DIR`.
- `backup-config` is a config-only backup shortcut (no savegame files).
- `profile` and `restore-backup` are request-driven jobs. The interactive menu writes request files and starts these jobs automatically.
- Manual non-menu triggering of `profile`/`restore-backup` requires a valid request JSON in `server_manager/requests`.
