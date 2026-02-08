# Logging

Aktuelles Logverhalten im `server_manager`:

## Format

Logs kommen aus `server_manager/shared/common`:
- `DEBUG - [pid] - ...`
- `INFO - ...`
- `WARN - ...`
- `ERROR - ...`
- `CRITIAL - ...`
- `FATAL - ...`

Hinweise:
- Keine Manager-Timestamps im Prefix.
- Filterung über numerisches `log_level` (intern).
- Farbe nur bei:
  - `LOG_COLOR=true`
  - und TTY (`-t 1`)

## Quellen

- Prozesslogs gehen über `stdout_syslog=true` in Supervisor (`/etc/supervisor/supervisord.conf`).
- `rsyslog` wird im Bootstrap für stdout konfiguriert.
- Enshrouded schreibt zusätzlich in `logDirectory` aus `enshrouded_server.json` (default `./logs`).

## Relevante Settings

- `LOG_COLOR` (`true|false`)
- `ENSHROUDED_LOG_DIR`
- `ENSHROUDED_SAVE_DIR`
- `WINEDEBUG`
