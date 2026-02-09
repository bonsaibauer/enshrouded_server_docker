# Interactive Shell Menu (`ctl menu`)

The Server Manager includes an interactive shell menu to manage profiles and edit the persistent JSON configs inside the container volume.

## Run

The menu requires a TTY. Always use `-it`.

```bash
docker exec -it <container> ctl menu
```

There is also a direct command alias:

```bash
docker exec -it <container> menu
```

## Navigation

- Enter a number and press Enter
- `[0]` is always `Back` (or `Exit` in the main menu)
- Prompts use `yes/no` (also accepts `y/n`)

## Main Menu

1. `Enshrouded Server Settings`
2. `Server Manager Settings`
3. `Other ctl Commands`

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

4. `Restore from backup`
   - Lists timestamped config backups from `BACKUP_DIR/profiles`
   - Restores a selected backup by replacing `/home/enshrouded/server/enshrouded_server.json`

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

4. `Restore from backup`
   - Lists timestamped config backups from `BACKUP_DIR/profiles`
   - Restores a selected backup by replacing `/home/enshrouded/server/server_manager/server_manager.json`

### What Existing Commands Are Used?

When switching Server Manager profiles the menu reuses existing profile/init helpers and Supervisor programs:

- `ensure_manager_profile_file` (copies template into the volume profile store)
- `supervisorctl stop enshrouded-server` (before replacing the active config)
- `supervisorctl start|restart enshrouded-server` (after saving/applying, to activate changes)
- `supervisorctl start enshrouded-bootstrap` (optional; refreshes cron schedules / runs bootstrap hooks, but does not start the server)

## Other ctl Commands

This submenu is a convenience wrapper around existing `ctl` commands:

- `status`, `start`, `stop`, `restart`
- `update`, `backup`, `password-view`, `scheduled-restart`, `force-update`
- `bootstrap`
- `cron-start`, `cron-stop`, `cron-restart`

Note: reset commands (`profile-reset`, `enshrouded-profile-reset`) are intentionally not listed here, because the menu provides profile delete/select flows instead.

## Profile Selection Persistence

The menu stores the selected profiles in:

- `/home/enshrouded/server/server_manager/profile_selection.json`

Keys:

- `enshrouded`
- `manager`

If this file exists, it overrides `EN_PROFILE` and `MANAGER_PROFILE` (so you can switch profiles without changing container env vars).

To go back to pure env-var selection, delete the file.

## Config Backups (Automatic)

Whenever the menu writes or replaces config files, it creates a timestamped backup under:

- `BACKUP_DIR/profiles`

By default (`backupDir = "backups"`), this is:

- `/home/enshrouded/server/backups/profiles`

Backups are created when you:

- `Save` in the JSON editors
- apply a profile template (`Select new profile`)
- use the restore menu (`Restore from backup`)
- run the existing reset commands (`ctl profile-reset`, `ctl enshrouded-profile-reset`)

## Settings Precedence (Important)

Some settings can be provided via container environment variables (see `docs/environment.md`). If a value is set via env var, it is treated as the source of truth and may overwrite manual JSON edits when bootstrap runs.

Practical rule:

- If you want the menu-edited JSON to stay in control, avoid setting the same option via container env vars.

## Troubleshooting

- If the menu looks broken or does not accept input:
  - Use `docker exec -it ...`
- If you change settings but they do not take effect:
  - Restart the server (`ctl restart`) or run bootstrap (`ctl bootstrap`)
