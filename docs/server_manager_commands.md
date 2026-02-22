# Server Manager Commands

Use your container name instead of `enshroudedserver`.
For full container shutdowns, use a 90-second grace period: `docker stop -t 90 enshroudedserver`.

Note: All commands below are shown without the `server` prefix. Internally, they are aliases to the same script. If needed, you can still run them as `docker exec enshroudedserver server <command>`.
Most commands can run without extra arguments and then use defaults from `server_manager.json` / `enshrouded_server.json` (for example cron schedules and player-check behavior).

## Simple Commands (Quick Readme)

- `docker exec enshroudedserver status`: Shows supervisor status for all jobs (`server`, `updater`, `crond`, ...).
- `docker exec -it enshroudedserver menu`: Opens the interactive management menu.
- `docker exec enshroudedserver start`: Starts the server job.
- `docker exec enshroudedserver stop`: Stops the server job.
- `docker stop -t 90 enshroudedserver`: Stops the whole container with safe grace time.
- `docker exec enshroudedserver restart`: Runs the restart job with defaults from `server_manager.json`.
- `docker exec enshroudedserver update`: Runs normal updater flow (install if needed, then start server).
- `docker exec enshroudedserver update force`: Forces full update path.
- `docker exec enshroudedserver backup`: Creates a manual backup with default includes (savegame + both config files).
- `docker exec enshroudedserver backup list`: Lists available backup ZIP files (manual + scheduled).
- `docker exec enshroudedserver backup inspect <backup.zip>`: Shows which components are in a backup ZIP.
- `docker exec enshroudedserver backup restore <backup.zip> [savegame|enshrouded|manager|all]`: Restores selected parts (default target is `all`).
- `docker exec enshroudedserver profile <manager|enshrouded> <apply|reset> [profile]`: Applies/resets profile (with config backup).
- `docker exec enshroudedserver password-view`: Shows user group rights/passwords.
- `docker exec enshroudedserver cron sync`: Rewrites cron table from current `server_manager.json`.
- `docker exec enshroudedserver cron [start|stop|restart|status]`: Controls `crond` service.

## Chapter 1 - Core Commands

### 1.1 `status`

```bash
docker exec enshroudedserver status
```

- What this command does: Shows supervisor status for all relevant jobs.
- `docker exec enshroudedserver status`: Quickly confirms whether `server`, `updater`, `crond`, and others are running.
- Args: None.

### 1.2 `menu`

```bash
docker exec -it enshroudedserver menu [--screen <id>] [--once] [--no-clear]
```

- What this command does: Starts the interactive Server Manager menu.
- `docker exec -it enshroudedserver menu --screen main --once`: Opens the main screen once and then exits.
- Args:
- `--screen <id>`: Starts directly on a specific menu screen.
- `--once`: Runs only a single menu cycle.
- `--no-clear`: Does not clear the terminal between menu screens.

### 1.3 `start`

```bash
docker exec enshroudedserver start
```

- What this command does: Starts the server job via supervisor.
- `docker exec enshroudedserver start`: Use after a manual stop or maintenance.
- Args: None.

### 1.4 `stop`

```bash
docker exec enshroudedserver stop
```

- What this command does: Stops the server job via supervisor.
- `docker exec enshroudedserver stop`: Use before maintenance or container updates.
- Internal stop grace for this command is 90 seconds (`supervisord` `stopwaitsecs=90`).
- Full container stop: `docker stop -t 90 enshroudedserver` (recommended for graceful container shutdown).
- Args: None.

### 1.5 `restart`

```bash
docker exec enshroudedserver restart [force|player-check|no-player-check]
```

- What this command does: Runs the controlled restart job.
- Restart flow: `stop -> wait (downtime) -> start`.
- `docker exec enshroudedserver restart player-check`: Restarts only when no players are online.
- `docker exec enshroudedserver restart`: Uses configured defaults (for example `restartCheckPlayers`).
- Downtime wait is controlled by `RESTART_DOWNTIME_SECONDS` (default: `3`).
- Args:
- `force`: Forces restart.
- `player-check`: Enforces player check before restart.
- `no-player-check`: Restarts without player check.
- Advanced also supported: `--force`, `--player-check`, `--no-player-check`.

### 1.6 `update`

```bash
docker exec enshroudedserver update [force|check|player-check|no-player-check]
```

- What this command does: Starts the updater job.
- `docker exec enshroudedserver update force`: Forces a full update (useful for broken installs or branch mismatch issues).
- Args:
- `force`: Force full update path.
- `check`: Check update availability only (no install/start).
- `player-check`: Enforce player check before update.
- `no-player-check`: Skip online player check before update.
- Advanced also supported: `--force`, `--check-only`, `--player-check`, `--no-player-check`.

### 1.7 `scheduled-restart`

```bash
docker exec enshroudedserver scheduled-restart [force|player-check|no-player-check]
```

- What this command does: Manually runs the scheduled restart path.
- `docker exec enshroudedserver scheduled-restart force`: Tests the same restart flow used by cron.
- Args:
- `force`: Forces restart.
- `player-check`: Restarts only when empty.
- `no-player-check`: Restarts without player check.
- Advanced also supported: `--force`, `--player-check`, `--no-player-check`.

### 1.8 `scheduled-backup`

```bash
docker exec enshroudedserver scheduled-backup
```

- What this command does: Manually runs the scheduled backup path.
- `docker exec enshroudedserver scheduled-backup`: Tests the same backup flow used by cron.
- Args: None.

## Chapter 2 - Backup and Restore

### 2.1 `backup` (scheduled/manual)

```bash
docker exec enshroudedserver backup [manual|scheduled]
```

- What this command does: Creates a backup with controlled content selection.
- `docker exec enshroudedserver backup`: Creates a default manual backup (simple mode).
- Args:
- `manual`: Manual backup mode.
- `scheduled`: Scheduled profile backup mode.
- Advanced also supported: `--mode`, `--savegame`, `--enshrouded-config`, `--manager-config`, `--cleanup`.

### 2.2 `backup list`

```bash
docker exec enshroudedserver backup list
```

- What this command does: Lists available backup ZIP files.
- `docker exec enshroudedserver backup list`: Useful to get names for `inspect` and `restore`.
- Args:
- `list`: List only, no backup/restore execution.
- Advanced also supported: `--mode list`.

### 2.3 `backup inspect`

```bash
docker exec enshroudedserver backup inspect <backup.zip>
```

- What this command does: Shows which content is available inside a backup ZIP.
- `docker exec enshroudedserver backup inspect my-backup.zip`: Verifies savegame/config presence before restore.
- Default output is human-readable (`yes/no` per component).
- Args:
- `inspect <backup.zip>`: Inspection mode with ZIP filename/path.
- Advanced also supported: `--mode inspect --zip <backup.zip>`.

### 2.4 `backup restore`

```bash
docker exec enshroudedserver backup restore <backup.zip> [savegame|enshrouded|manager|all]
```

- What this command does: Restores selected parts from a backup ZIP.
- `docker exec enshroudedserver backup restore my-backup.zip all`: Full restore from ZIP.
- Args:
- `restore <backup.zip> [target]`: Restore mode (default target is `all`).
- Advanced also supported: `--mode restore --zip <backup.zip> --restore <target> [--safety-backup true|false]`.

### 2.5 `backup-config`

```bash
docker exec enshroudedserver backup-config
```

- What this command does: Creates a manual config-only backup.
- `docker exec enshroudedserver backup-config`: Backs up config files without savegame data.
- Args: None.

### 2.6 ZIP resolution for `inspect` and `restore`

```bash
docker exec enshroudedserver backup restore my-backup.zip savegame
```

- What this command does: Uses only the ZIP filename, without full path.
- `docker exec enshroudedserver backup restore manual/my-backup.zip manager`: If the same filename exists multiple times, use `manual/...` or `scheduled/...`.
- Args note:
- The job searches `BACKUP_DIR/manual` and `BACKUP_DIR/scheduled` first.
- If the filename is unique, plain filename is enough.

## Chapter 3 - Profiles and Access

### 3.1 `profile`

```bash
docker exec enshroudedserver profile <manager|enshrouded> <apply|reset> [profile]
```

- What this command does: Applies profiles or resets to defaults.
- `docker exec enshroudedserver profile enshrouded apply default`: Applies the `default` Enshrouded profile.
- Args:
- `<manager|enshrouded>`: Profile target.
- `<apply|reset>`: Operation mode.
- `[profile]`: Profile name (required for `apply`).
- Note: A config backup is created by default before profile changes.
- Note: If `MANAGER_PROFILE`/`EN_PROFILE` is set via container ENV for the selected target, profile apply/reset is blocked.
- Advanced also supported: `--target`, `--action`, `--profile`, `--create-backup true|false`.

### 3.2 `password-view`

```bash
docker exec enshroudedserver password-view [text|json]
```

- What this command does: Shows group rights and passwords from server config.
- `docker exec enshroudedserver password-view json`: Machine-readable output for scripts/checks.
- Args:
- `text|json`: Output format (`text` by default).
- Advanced also supported: `--format text|json`.

## Chapter 4 - Validation, Bootstrap, Cron

### 4.1 `env-validation`

```bash
docker exec enshroudedserver env-validation [verify|init-runtime|check <name> <value>]
```

- What this command does: Validates environment values and runtime context.
- `docker exec enshroudedserver env-validation check ENSHROUDED_SLOT_COUNT 16`: Validates a single ENV value against rules.
- Args/subcommands:
- `verify`: Full ENV validation.
- `init-runtime`: Initializes runtime values/defaults.
- `check <name> <value>`: Validates one variable.

### 4.2 `bootstrap`

```bash
docker exec enshroudedserver bootstrap [job] [no-update] [entrypoint]
```

- What this command does: Runs the bootstrap job.
- `docker exec enshroudedserver bootstrap job no-update`: Initializes config/jobs and skips initial update.
- Args:
- `job`: Run bootstrap in job mode.
- `no-update`: Skip initial updater start.
- `entrypoint`: Run entrypoint mode.
- Advanced also supported: `--job`, `--no-update`, `--entrypoint`.

### 4.3 `cron`

```bash
docker exec enshroudedserver cron [sync|start|stop|restart|status]
```

- What this command does: Syncs cron schedules or controls the cron daemon.
- `docker exec enshroudedserver cron restart`: Restarts the cron daemon.
- Args:
- `sync`: Rewrite cron table from current config in `server_manager.json`.
- `start|stop|restart|status`: Cron daemon service actions.
- Advanced also supported: `--sync`, `--service <...>`, `--update-cron`, `--backup-cron`, `--restart-cron`.

### 4.4 `cron` service actions

```bash
docker exec enshroudedserver cron <start|stop|restart|status>
```

- What this command does: Controls the `crond` service.
- `docker exec enshroudedserver cron restart`: Restarts cron service cleanly.
- Args:
- `<start|stop|restart|status>`: Service action.
- Advanced also supported: `cron --service <start|stop|restart|status>`.

## Chapter 5 - Advanced/Internal Commands

### 5.1 `hook-run`

```bash
docker exec enshroudedserver hook-run <name> [command...]
```

- What this command does: Executes a named hook command.
- `docker exec enshroudedserver hook-run "manual test" "echo hook-ok"`: Tests hook integration and logging.
- Args:
- `<name>`: Log/display name.
- `[command...]`: Optional shell command to execute.
- Advanced also supported: `--name <name> [--command <command>]`.

### 5.2 `guard-run`

```bash
docker exec enshroudedserver guard-run <guard_mode> -- <call...>
```

- What this command does: Runs a call only if guard checks pass.
- `docker exec enshroudedserver guard-run core_ready -- supervisorctl status`: Runs `supervisorctl status` only when core readiness passes.
- Args:
- `<guard_mode>`: `core_ready|server_ready|job_ready:<job>`.
- `-- <call...>`: Actual command call.

### 5.3 `guard-require`

```bash
docker exec enshroudedserver guard-require <guard_mode> -- <call...>
```

- What this command does: Same as `guard-run`, but hard-fails when blocked.
- `docker exec enshroudedserver guard-require core_ready -- supervisorctl pid`: Fails immediately if guard conditions are not met.
- Args:
- `<guard_mode>`: `core_ready|server_ready|job_ready:<job>`.
- `-- <call...>`: Actual command call.
