# Environment Variables

This file documents the environment variables used by the current `server_manager` setup.

Value resolution order (most settings):
1. ENV
2. Runtime files (`/home/enshrouded/server/server_manager/server_manager.json`, `/home/enshrouded/server/enshrouded_server.json`)
3. Profile templates (only during initialization)

Profile selection is special:
- The menu persists profile selection in `server_manager.json` under `actualProfilManager` / `actualProfilEnshrouded`.
- `EN_PROFILE` / `MANAGER_PROFILE` ENV vars are mainly used for the first bootstrap (fresh volume / deleted config).

## Validation Rules

ENV input validation and interactive menu validation are driven by a single rule file:

- `server_manager/shared/validation/vars.json`

If you want to adjust allowed values, ranges, regex, or the menu hints for a variable, change that JSON.

The rules support:

- `required`: if `true`, empty/unset is invalid.
- `allowEmpty`: if `false`, empty string is invalid (but the variable can still be unset unless `required=true`).
- `envMode`: `hard` will abort bootstrap on invalid values, `soft` will only warn.
- `allowed`: optional menu hint override (otherwise the hint is derived from `type`/`enum`/`min`/`max`/`regex`/`list`).

## Variable Reference

The authoritative variable reference (descriptions, allowed values, JSON mappings, and menu grouping) is generated from the spec:

- `docs/vars.md`

Regenerate after changing `server_manager/shared/validation/vars.json`:

```bash
python scripts/gen_vars_md.py
```

## Backup Layout

There are two backup types:

1. Savegame backups (zip)
   - Triggered by `ctl backup` / `supervisorctl start enshrouded-backup`
   - The same Supervisor job is used for manual backups, cron backups (`BACKUP_CRON`), and safety backups before restore.
   - Stored in `BACKUP_DIR` (default: `/home/enshrouded/server/backups`)
   - Filename pattern: `YYYY-MM-DD_HH-MM-SS-$SAVEFILE_NAME.zip`
   - Retention: controlled by `BACKUP_MAX_COUNT` (only affects zip backups)
   - `BACKUP_MAX_COUNT` keeps the newest N zip backups and deletes older ones (nothing is overwritten)
   - Manual/safety backups also count toward `BACKUP_MAX_COUNT`
   - Example: `BACKUP_MAX_COUNT=7` keeps 7 total zip files even if you create additional manual backups between cron runs
   - Note: retention currently matches `*-$SAVEFILE_NAME.zip`. If you change `SAVEFILE_NAME`, older zip backups with the previous name are not pruned automatically.

2. Config backups (json)
   - Created automatically when the menu replaces/saves config files (and by reset commands)
   - Stored in `BACKUP_DIR/profiles` (default: `/home/enshrouded/server/backups/profiles`)
   - Filename pattern: `YYYY-MM-DD_HH-MM-SS_<label>.json` (labels: `server_manager`, `enshrouded_server`)
   - Retention: not automatically pruned
   - Not affected by `BACKUP_MAX_COUNT`

## Additional CLI Variable

| Variable | Description | Default |
|---|---|---|
| `SUPERVISORCTL_BIN` | Binary for the `ctl` wrapper | `supervisorctl` |
