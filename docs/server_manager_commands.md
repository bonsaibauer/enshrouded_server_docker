# Server Manager Commands

Aktuelle Commands laut `server_manager/entrypoints/ctl`.

## Direkt via docker exec

```bash
docker exec <container> status
docker exec <container> start
docker exec <container> stop
docker exec <container> restart
docker exec <container> update
docker exec <container> backup
docker exec <container> password-view
docker exec <container> scheduled-restart
docker exec <container> force-update
docker exec <container> profile-reset
docker exec <container> enshrouded-profile-reset
docker exec <container> bootstrap
docker exec <container> cron-start
docker exec <container> cron-stop
docker exec <container> cron-restart
```

## Alternativ über ctl

```bash
docker exec <container> ctl status
docker exec <container> ctl start
docker exec <container> ctl stop
docker exec <container> ctl restart
docker exec <container> ctl update
docker exec <container> ctl backup
docker exec <container> ctl password-view
docker exec <container> ctl scheduled-restart
docker exec <container> ctl force-update
docker exec <container> ctl profile-reset
docker exec <container> ctl enshrouded-profile-reset
docker exec <container> ctl bootstrap
docker exec <container> ctl cron-start
docker exec <container> ctl cron-stop
docker exec <container> ctl cron-restart
```

## Supervisor-Programmnamen

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

## password-view

Zeigt `userGroups` (Rechte + Passwort) aus der aktiven `enshrouded_server.json`.

```bash
docker exec <container> password-view
```
