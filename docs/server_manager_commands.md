# Server Manager Commands

Use your container name instead of `enshroudedserver`.

Note: All commands below are shown without the `server` prefix. Internally, they are aliases to the same script. If needed, you can still run them as `docker exec enshroudedserver server <command>`.

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
- Args: None.

### 1.5 `restart`

```bash
docker exec enshroudedserver restart [--check-players|--no-check-players] [--force]
```

- What this command does: Runs the controlled restart job.
- `docker exec enshroudedserver restart --check-players`: Restarts only when no players are online.
- Args:
- `--check-players`: Enforces player check before restart.
- `--no-check-players`: Restarts without player check.
- `--force`: Forces restart (effectively like no player check).

### 1.6 `update`

```bash
docker exec enshroudedserver update
```

- What this command does: Starts the updater job.
- `docker exec enshroudedserver update`: Checks/applies a normal update and starts the server afterward.
- Args: None.

### 1.7 `force-update`

```bash
docker exec enshroudedserver force-update
```

- What this command does: Forces a full update.
- `docker exec enshroudedserver force-update`: Useful for broken installs or branch mismatch issues.
- Args: None.

### 1.8 `scheduled-restart`

```bash
docker exec enshroudedserver scheduled-restart [--check-players|--no-check-players] [--force]
```

- What this command does: Manually runs the scheduled restart path.
- `docker exec enshroudedserver scheduled-restart --force`: Tests the same restart flow used by cron.
- Args:
- `--check-players`: Restarts only when empty.
- `--no-check-players`: Restarts without player check.
- `--force`: Forces restart.

### 1.9 `scheduled-backup`

```bash
docker exec enshroudedserver scheduled-backup
```

- What this command does: Manually runs the scheduled backup path.
- `docker exec enshroudedserver scheduled-backup`: Tests the same backup flow used by cron.
- Args: None.

## Chapter 2 - Backup and Restore

### 2.1 `backup` (scheduled/manual)

```bash
docker exec enshroudedserver backup --mode scheduled|manual [--savegame true|false] [--enshrouded-config true|false] [--manager-config true|false] [--cleanup true|false]
```

- What this command does: Creates a backup with controlled content selection.
- `docker exec enshroudedserver backup --mode manual --savegame true --enshrouded-config true --manager-config true --cleanup false`: Creates a full manual backup without cleanup.
- Args:
- `--mode scheduled|manual`: Backup type.
- `--savegame true|false`: Include/exclude savegame.
- `--enshrouded-config true|false`: Include/exclude `enshrouded_server.json`.
- `--manager-config true|false`: Include/exclude `server_manager.json`.
- `--cleanup true|false`: Cleanup old backups according to retention.

### 2.2 `backup --mode list`

```bash
docker exec enshroudedserver backup --mode list
```

- What this command does: Lists available backup ZIP files.
- `docker exec enshroudedserver backup --mode list`: Useful to get names for `inspect` and `restore`.
- Args:
- `--mode list`: List only, no backup/restore execution.

### 2.3 `backup --mode inspect`

```bash
docker exec enshroudedserver backup --mode inspect --zip <backup.zip>
```

- What this command does: Shows which content is available inside a backup ZIP.
- `docker exec enshroudedserver backup --mode inspect --zip my-backup.zip`: Verifies savegame/config presence before restore.
- Args:
- `--mode inspect`: Inspection mode.
- `--zip <backup.zip>`: ZIP filename or path.

### 2.4 `backup --mode restore`

```bash
docker exec enshroudedserver backup --mode restore --zip <backup.zip> --restore <savegame|enshrouded|manager|all> [--safety-backup true|false]
```

- What this command does: Restores selected parts from a backup ZIP.
- `docker exec enshroudedserver backup --mode restore --zip my-backup.zip --restore all --safety-backup false`: Full restore without creating an additional safety backup.
- Args:
- `--mode restore`: Restore mode.
- `--zip <backup.zip>`: ZIP filename or path.
- `--restore <...>`: Target `savegame|enshrouded|manager|all` (also comma-combinable).
- `--safety-backup true|false`: Create an extra safety backup before restore.

### 2.5 `backup-config`

```bash
docker exec enshroudedserver backup-config
```

- What this command does: Creates a manual config-only backup.
- `docker exec enshroudedserver backup-config`: Backs up config files without savegame data.
- Args: None.

### 2.6 ZIP resolution for `inspect` and `restore`

```bash
docker exec enshroudedserver backup --mode restore --zip my-backup.zip --restore savegame
```

- What this command does: Uses only the ZIP filename, without full path.
- `docker exec enshroudedserver backup --mode restore --zip manual/my-backup.zip --restore manager`: If the same filename exists multiple times, use `manual/...` or `scheduled/...`.
- Args note:
- The job searches `BACKUP_DIR/manual` and `BACKUP_DIR/scheduled` first.
- If the filename is unique, plain filename is enough.

## Chapter 3 - Profiles and Access

### 3.1 `profile`

```bash
docker exec enshroudedserver profile --target <manager|enshrouded> --action <apply|reset> [--profile <name>] [--create-backup true|false]
```

- What this command does: Applies profiles or resets to defaults.
- `docker exec enshroudedserver profile --target enshrouded --action apply --profile default --create-backup true`: Applies the `default` Enshrouded profile and creates a config backup first.
- Args:
- `--target <manager|enshrouded>`: Target profile type.
- `--action <apply|reset>`: Apply or reset action.
- `--profile <name>`: Profile name, required for `apply`.
- `--create-backup true|false`: Create config backup before profile change.

### 3.2 `password-view`

```bash
docker exec enshroudedserver password-view [--format text|json]
```

- What this command does: Shows group rights and passwords from server config.
- `docker exec enshroudedserver password-view --format json`: Machine-readable output for scripts/checks.
- Args:
- `--format text|json`: Output format.

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
docker exec enshroudedserver bootstrap [--job] [--no-update]
```

- What this command does: Runs the bootstrap job.
- `docker exec enshroudedserver bootstrap --job --no-update`: Initializes config/jobs and skips initial update.
- Args:
- `--job`: Force job mode.
- `--no-update`: Skip initial updater start.

### 4.3 `cron`

```bash
docker exec enshroudedserver cron [--sync] [--update-cron "<expr>"] [--backup-cron "<expr>"] [--restart-cron "<expr>"]
```

- What this command does: Writes/updates cron schedules.
- `docker exec enshroudedserver cron --sync --update-cron "0 */6 * * *" --backup-cron "0 3 * * *" --restart-cron "0 5 * * *"`: Sets fixed schedules for update/backup/restart.
- Args:
- `--sync`: Rewrite cron table.
- `--update-cron "<expr>"`: Update schedule.
- `--backup-cron "<expr>"`: Backup schedule.
- `--restart-cron "<expr>"`: Restart schedule.

### 4.4 `cron --service`

```bash
docker exec enshroudedserver cron --service <start|stop|restart|status>
```

- What this command does: Controls the `crond` service.
- `docker exec enshroudedserver cron --service restart`: Restarts cron service cleanly.
- Args:
- `--service <start|stop|restart|status>`: Service action.

## Chapter 5 - Advanced/Internal Commands

### 5.1 `hook-run`

```bash
docker exec enshroudedserver hook-run --name <name> --command <cmd>
```

- What this command does: Executes a named hook command.
- `docker exec enshroudedserver hook-run --name "manual test" --command "echo hook-ok"`: Tests hook integration and logging.
- Args:
- `--name <name>`: Log/display name.
- `--command <cmd>`: Shell command to run.

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
