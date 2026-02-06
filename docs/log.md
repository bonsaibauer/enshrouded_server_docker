# Logging Behavior

## Log Output (stdout)
| Output example (as printed) | Origin / context | Produced by | Controls / notes |
|---|---|---|---|
| `2026-02-06T17:45:12Z [INFO] [server_manager] Start server` | Server Manager core | `log()` / `info()` | Includes manager UTC timestamp. Filtered by `LOG_LEVEL`. `LOG_CONTEXT` changes the label. Colors only when stdout is a TTY (not in `docker logs`). |
| `2026-02-06T17:45:13Z [OK] [server_manager] Start complete: server online` | Server Manager core | `log()` / `ok()` | Includes manager UTC timestamp. `OK` is a distinct level. |
| `2026-02-06T17:45:30Z [WARN] [server_manager] Stop detected: server process exited` | Server Manager core | `log()` / `warn()` | Includes manager UTC timestamp. Same format as INFO/OK/ERROR. |
| `2026-02-06T17:45:31Z [INFO] [server_manager] [update] SteamCMD: ...` | Manager command output (piped) | `run_logged` / `run_hook_logged` -> `log_pipe` | Manager timestamp is added to all piped output. Context label is set by the caller (e.g., `update`, `backup`). |
| `2026-02-06T17:45:32Z [INFO] [server_manager] [server-log] [Session] 'HostOnline' (up)!` | Enshrouded server log file (streamed) | `server-manager-logstream` or `manager.sh logs` | Manager timestamp is added to each streamed server log line. Controlled by `LOG_TO_STDOUT`, `LOG_TAIL_LINES`, `LOG_POLL_INTERVAL`, `LOG_FILE_PATTERN`. |
| `2026-02-06T17:45:50Z [WARN] [server_manager] [supervisor] supervisord: WARN ...` | Supervisor log file (streamed) | `server-manager-supervisor-logstream` | Manager timestamp is added. The supervisor line timestamp is stripped to avoid double timestamps. Active only when `LOG_TO_STDOUT=true`. |
| `2026-02-06T17:45:40Z [ERROR] [server_manager] [syslog] TAG: Message` | Syslog (streamed) | `server-manager-syslog` + `server-manager-syslog-logstream` | Manager timestamp is added. The syslog file timestamp is stripped to avoid double timestamps. Active only when `LOG_TO_STDOUT=true` and `rsyslogd` exists. Severity is mapped to debug/info/warn/error. |

## Log Files and Locations
| File or directory | Produced by | Selection / usage | Notes |
|---|---|---|---|
| `<INSTALL_PATH>/logs` (default) | Enshrouded server | Used as log directory if no override is set | `INSTALL_PATH` defaults to `/home/steam/enshrouded`. |
| `<ENSHROUDED_LOG_DIR>` | Enshrouded server | Overrides log directory when set | Can be absolute or relative to `INSTALL_PATH`. |
| `<logDirectory>` from `enshrouded_server.json` | Enshrouded server | Used when `ENSHROUDED_LOG_DIR` is not set | Default is `./logs`. |
| `/var/run/enshrouded/server-manager-supervisord.log` | supervisord | Streamed by supervisor logstream | Fixed path. |
| `/var/run/enshrouded/server-manager-syslog.log` | rsyslog | Streamed by syslog logstream | Fixed path; created only if `rsyslogd` is available. |

## Logging Settings
| Setting | Default | Scope | Detailed behavior |
|---|---|---|---|
| `ENSHROUDED_LOG_DIR` | unset | Server log files | Overrides log directory. Absolute path stays absolute; relative path is resolved under `INSTALL_PATH`. |
| `logDirectory` (in `enshrouded_server.json`) | `./logs` | Server log files | Used when `ENSHROUDED_LOG_DIR` is not set. |
| `LOG_FILE_PATTERN` | `*.log` | Server log selection | Used by logstream and `manager.sh logs` to find the newest log file (via `find -name`). |
| `LOG_TO_STDOUT` | `true` | Streaming | Enables or disables: server logstream, syslog daemon, syslog logstream, supervisor logstream. Manager core logs still go to stdout. |
| `LOG_TAIL_LINES` | `200` | Streaming | Number of lines passed to `tail -n` for server log streaming and `manager.sh logs`. |
| `LOG_POLL_INTERVAL` | `2` | Streaming | Seconds between checks for a newer log file (log rotation handling). |
| `LOG_LEVEL` | `info` | Manager core logs | Filters only timestamped manager logs (`log()` / `info()` / `warn()` / `error()` / `ok()` / `debug()`). It does not filter streamed or piped lines. |
| `LOG_CONTEXT` | `server_manager` | Manager core logs | Default context label for manager logs. Streamed logs set their own context (`server-log`, `supervisor`, `syslog`, etc.). |
| `NO_COLOR` | unset | Output formatting | When stdout is a TTY, level labels use ANSI colors. `docker logs` shows plain text because stdout is not a TTY. |
