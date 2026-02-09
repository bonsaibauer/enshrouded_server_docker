# Logging

Current logging behavior in `server_manager`:

## Format

Logs are implemented in `server_manager/shared/common`:
- `DEBUG - [pid] - ...`
- `INFO - ...`
- `WARN - ...`
- `ERROR - ...`
- `CRITIAL - ...`
- `FATAL - ...`

Notes:
- No server_manager timestamps in the prefix.
- Filtering via numeric `log_level` (internal).
- Color only when:
  - `LOG_COLOR=true`
  - and TTY (`-t 1`)

## Sources

- Process logs are routed into Supervisor via `stdout_syslog=true` (`/etc/supervisor/supervisord.conf`).
- `rsyslog` is configured for stdout during bootstrap.
- Enshrouded also writes to `logDirectory` from `enshrouded_server.json` (default `./logs`).

## Relevant Settings

- `LOG_COLOR` (`true|false`)
- `ENSHROUDED_LOG_DIR`
- `ENSHROUDED_SAVE_DIR`
- `WINEDEBUG`
