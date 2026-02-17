# Server Manager Commands

Current commands according to `server_manager/jobs/cmd`.

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

## Alternative via cmd

```bash
docker exec enshroudedserver cmd status
docker exec -it enshroudedserver cmd menu
docker exec enshroudedserver cmd start
docker exec enshroudedserver cmd stop
docker exec enshroudedserver cmd restart
docker exec enshroudedserver cmd update
docker exec enshroudedserver cmd backup
docker exec enshroudedserver cmd backup-config
docker exec enshroudedserver cmd restore-backup
docker exec enshroudedserver cmd profile
docker exec enshroudedserver cmd password-view
docker exec enshroudedserver cmd scheduled-restart
docker exec enshroudedserver cmd force-update
docker exec enshroudedserver cmd bootstrap
docker exec enshroudedserver cmd cron-start
docker exec enshroudedserver cmd cron-stop
docker exec enshroudedserver cmd cron-restart
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
