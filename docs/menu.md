# Interactive Shell Menu (`ctl menu`)

The Server Manager includes an interactive shell menu to manage profiles and edit the persistent JSON configs inside the container volume.

## Run

The menu requires a TTY. Always use `-it`.

Replace `enshroudedserver` with your container name (see `docker ps`).

```bash
docker exec -it enshroudedserver ctl menu
```

There is also a direct command alias:

```bash
docker exec -it enshroudedserver menu
```

## Navigation

- Enter a number and press Enter
- `[0]` is always `Back` (or `Exit` in the main menu)
- Prompts use `yes/no` (also accepts `y/n`)
- `[ENV]` marks settings controlled by container environment variables (locked in the editors)

## Main Menu

1. `Enshrouded Server Settings`
2. `Server Manager Settings`
3. `Backups`
4. `start`
5. `stop`
6. `restart`
7. `update`
8. `force-update`
9. `password-view`
10. `Create Savegame Backup (.zip)`
11. `Other ctl Commands`

Notes:

- `Create Savegame Backup (.zip)` is a shortcut for `Backups -> Create savegame backup now (.zip)`.
- The items `start/stop/restart/update/force-update/password-view` are the same actions as `ctl <command>` and are shown in the main menu for convenience.

## Enshrouded Server Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/enshrouded_server.json` (persistent volume file)
   - The editor works on a temporary copy and only writes to the real file when you choose `Save`
   - Includes submenus for:
      - `gameSettings`
      - `userGroups`
   - Validates inputs (ports, slots, booleans, tags, game setting ranges/enums)
   - When saving, the menu will ask to stop `enshrouded-server` first if it is running
   - Save options:
      - `Save`
      - `Save and restart server`
      - `Save and run bootstrap`

2. `Delete current profile`
   - Guided flow to replace the active config with a selected profile
   - The menu will confirm and stop `enshrouded-server` (if running) before replacing `/home/enshrouded/server/enshrouded_server.json`

3. `Select new profile`
     - Lists profile templates from `/usr/local/etc/enshrouded/profiles/enshrouded/`
     - If an active config exists, the menu will confirm and then replace it when applying the selected profile
     - Applies the selected template to `/home/enshrouded/server/enshrouded_server.json`
     - Ensures `.bans` exists and generates missing `userGroups[].password` values
     - Afterwards you should start/restart the server to apply changes.
     - Bootstrap is available as a convenience (note: bootstrap does not start the server).

### What Existing Commands Are Used?

When switching Enshrouded profiles the menu uses the existing Supervisor programs via `supervisorctl`:

- `supervisorctl stop enshrouded-server` (before editing/saving or deleting/replacing the active config)
- `supervisorctl start|restart enshrouded-server` (after saving/applying, to activate changes)
- `supervisorctl start enshrouded-bootstrap` (optional; refreshes cron schedules / runs bootstrap hooks, but does not start the server)

## Server Manager Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/server_manager/server_manager.json`
   - Validates inputs using the existing validation logic from `server_manager/shared/env`
   - When saving, the menu will ask to stop `enshrouded-server` first if it is running
   - Save options:
      - `Save`
      - `Save and run bootstrap` (recommended to refresh cron schedules)

2. `Delete current profile`
   - Guided flow to replace the active config with a selected profile
   - The menu will confirm and stop `enshrouded-server` (if running) before replacing `/home/enshrouded/server/server_manager/server_manager.json`

3. `Select new profile`
     - Lists template profiles from `/usr/local/etc/enshrouded/profiles/manager/`
     - If an active config exists, the menu will confirm and then replace it when applying the selected profile
     - Copies the selected template into:
       - the profile store: `/home/enshrouded/server/profile/<name>/<name>_server_manager.json`
       - the active config: `/home/enshrouded/server/server_manager/server_manager.json`
   - Afterwards you can:
      - restart the server, or
      - run bootstrap (recommended)

### What Existing Commands Are Used?

When switching Server Manager profiles the menu reuses existing profile/init helpers and Supervisor programs:

- `ensure_manager_profile_file` (copies template into the volume profile store)
- `supervisorctl stop enshrouded-server` (before replacing the active config)
- `supervisorctl start|restart enshrouded-server` (after saving/applying, to activate changes)
- `supervisorctl start enshrouded-bootstrap` (optional; refreshes cron schedules / runs bootstrap hooks, but does not start the server)

## Backups

This submenu provides restore operations for:

- the persistent JSON configs (timestamped backups in `BACKUP_DIR/profiles`)
- the savegame backups (zip files in `BACKUP_DIR`)

Menu options:

1. `Restore Enshrouded settings (enshrouded_server.json)`
   - If no config backups exist yet, the menu can create a backup of the current config.
   - Before restoring, the menu offers to create a safety backup of the current config.
2. `Restore Server Manager settings (server_manager.json)`
   - If no config backups exist yet, the menu can create a backup of the current config.
   - Before restoring, the menu offers to create a safety backup of the current config.
3. `Create savegame backup now (.zip)`
   - Runs `supervisorctl start enshrouded-backup`
4. `Restore savegame from .zip backup`
   - Lists zip backups from `BACKUP_DIR` (pattern: `*-$SAVEFILE_NAME.zip`)
   - If no zip backups exist yet, the menu can create one first.
   - Stops `enshrouded-server` first (required)
   - Optional: create a backup of the current savegame before restoring
   - Confirms before deleting current save files and extracting the selected backup

Notes:

- Savegame zip backups are always created by the same Supervisor job (`enshrouded-backup`), no matter if you trigger it manually (menu / `ctl backup`), via cron (`BACKUP_CRON`), or as a safety backup before restore.
- `BACKUP_MAX_COUNT` keeps the newest N zip backups and deletes older ones (nothing is overwritten). Manual/safety backups count toward the same limit.
- Config JSON backups under `BACKUP_DIR/profiles` are not affected by `BACKUP_MAX_COUNT`.

Example:

If `BACKUP_MAX_COUNT=7` and cron creates one backup per day, you will keep the newest 7 zip files. Creating extra manual/safety backups will still keep only 7 total zip files and may prune older daily backups sooner.

## Other ctl Commands

This submenu is a convenience wrapper around existing `ctl` commands:

- `status`
- `scheduled-restart`
- `bootstrap`
- `cron-start`, `cron-stop`, `cron-restart`

Note: reset commands (`profile-reset`, `enshrouded-profile-reset`) are intentionally not listed here, because the menu provides profile delete/select flows instead.

## Profile Selection Persistence

The menu stores the selected profiles in the Server Manager config file:

- `/home/enshrouded/server/server_manager/server_manager.json`

Keys (single source of truth):

- `actualProfilManager`
- `actualProfilEnshrouded`

The initial ENV selectors are captured once for transparency:

- `MANAGER_PROFILE`
- `EN_PROFILE`

`EN_PROFILE` / `MANAGER_PROFILE` are only used when no persisted selectors exist yet (fresh volume / deleted config).

## Config Backups (Automatic)

Whenever the menu writes or replaces config files, it creates a timestamped backup under:

- `BACKUP_DIR/profiles`

By default (`backupDir = "backups"`), this is:

- `/home/enshrouded/server/backups/profiles`

Backups are created when you:

- `Save` in the JSON editors
- apply a profile template (`Select new profile`)
- run the existing reset commands (`ctl profile-reset`, `ctl enshrouded-profile-reset`)

Retention:

- Config backups are not automatically pruned. If you want retention, delete old files manually in `BACKUP_DIR/profiles`.

## Settings Precedence (Important)

Some settings can be provided via container environment variables (see `docs/environment.md`). If a value is set via env var, it is treated as the source of truth and may overwrite manual JSON edits when bootstrap runs.

Practical rule:

- If you want the menu-edited JSON to stay in control, avoid setting the same option via container env vars.

Behavior in the menu:

- The JSON editors show `[ENV]` next to locked fields and will block editing them.
- Before selecting a profile template, the menu shows a warning listing active env overrides and asks for confirmation.

## Troubleshooting

- If the menu looks broken or does not accept input:
  - Use `docker exec -it ...`
- If you change settings but they do not take effect:
  - Restart the server (`ctl restart`) or run bootstrap (`ctl bootstrap`)
