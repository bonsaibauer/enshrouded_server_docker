# Interactive Shell Menu (`server menu`)

The Server Manager includes an interactive shell menu to manage profiles and edit the persistent JSON configs inside the container volume.

## Run

The menu requires a TTY. Always use `-it`.

Replace `enshroudedserver` with your container name (see `docker ps`).

```bash
docker exec -it enshroudedserver server menu
```

## Navigation

- Enter a number (or `b`/`m`/`x`) and press Enter
- `b` = Back in submenus (`b` in main menu exits)
- `m` = Main Menu
- `x` = Exit menu
- Prompts use `yes/no` (also accepts `y/n`)
- `[ENV]` marks settings controlled by container environment variables (locked in the editors)
- Some actions (apply/restore) run as Supervisor jobs; their output is visible in `docker logs`.

Exit behavior:

- If `server` is `STOPPED` when you exit, the menu asks whether it should be started before closing.
- If confirmed, the menu always uses the unified `bootstrap + start` flow.

## Main Menu

1. `Enshrouded Server Settings`
2. `Server Manager Settings`
3. `Backup Menu`
4. `Start Server`
5. `Stop Server`
6. `Restart Server`
7. `Update Server`
8. `update_force`
9. `View Passwords`
10. `Create Manual Backup (.zip)`
11. `Other Commands`

Notes:

- `Create Manual Backup (.zip)` is a shortcut for `Backup Menu -> Create manual full backup now`.
- The items `start/stop/restart/update/password-view` are the same actions as `server <command>` and are shown in the main menu for convenience.
- `update_force` in the menu maps to `update force`.

## Enshrouded Server Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/enshrouded_server.json` (persistent volume file)
   - When entering the editor, the menu will ask to stop `server` first if it is running (required)
   - Changes are written immediately to the real file (no explicit Save step)
   - Includes submenus for:
      - `gameSettings`
      - `userGroups`
   - Validates inputs (ports, slots, booleans, tags, game setting ranges/enums)
   - After editing, use the main menu (`start/restart`) to apply changes, or exit the menu (`x`) and confirm the start prompt.

2. `Reset current profile`
   - Guided flow to replace the active config with a selected profile
   - The menu will confirm and stop `server` (if running) before replacing `/home/enshrouded/server/enshrouded_server.json`

3. `Select and apply profile`
     - Lists profile templates from `EN_PROFILE_DIR` (default: `/home/enshrouded/server/profiles/enshrouded/`, seeded from `/usr/local/etc/enshrouded/profiles/enshrouded/`)
     - If an active config exists, the menu will confirm and then replace it when applying the selected profile
     - Applies the selected template to `/home/enshrouded/server/enshrouded_server.json`
     - Ensures `.bans`/`.bannedAccounts` exist and generates missing `userGroups[].password` values
     - Preserves existing ban lists (`.bannedAccounts` and legacy `.bans`) across apply/reset operations.
     - Afterwards the menu offers a unified `bootstrap + start` action.

4. `Manage Banned Accounts`
   - Lists current banned accounts from `.bannedAccounts` and legacy `.bans`.
   - Lets you select an entry and remove it (unban).
   - Changes are written to both ban arrays for compatibility.

### What Existing Commands Are Used?

When switching Enshrouded profiles the menu uses the existing Supervisor programs via `supervisorctl`:

- `supervisorctl stop server` (before editing or deleting/replacing the active config)
- `supervisorctl start|restart server` (after editing/applying, to activate changes)
- `supervisorctl start bootstrap` (optional; refreshes cron schedules / runs bootstrap hooks, but does not start the server)

## Server Manager Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/server_manager/server_manager.json`
   - Validates inputs using the embedded runtime validation logic in `server_manager/jobs/menu`
   - When entering the editor, the menu will ask to stop `server` first if it is running (required)
   - Changes are written immediately to the real file (no explicit Save step)
   - After editing, use the main menu (`start/restart`) to apply changes, or exit the menu (`x`) and confirm the start prompt.

2. `Reset current profile`
   - Guided flow to replace the active config with a selected profile
   - The menu will confirm and stop `server` (if running) before replacing `/home/enshrouded/server/server_manager/server_manager.json`

3. `Select and apply profile`
     - Lists profiles from `MANAGER_PROFILE_DIR` (default: `/home/enshrouded/server/profiles/manager/`, seeded from `/usr/local/etc/enshrouded/profiles/manager/`)
     - If an active config exists, the menu will confirm and then replace it when applying the selected profile
     - Applies `/home/enshrouded/server/profiles/manager/<name>_server_manager.json` to `/home/enshrouded/server/server_manager/server_manager.json`
   - Afterwards the menu offers a unified `bootstrap + start` action.

### What Existing Commands Are Used?

When switching Server Manager profiles the menu reuses existing profile/init helpers and Supervisor programs:

- `ensure_manager_profile_file` (ensures profile exists in `/home/enshrouded/server/profiles/manager/`, seeded from shipped templates if missing)
- `supervisorctl stop server` (before replacing the active config)
- `supervisorctl start|restart server` (after editing/applying, to activate changes)
- `supervisorctl start bootstrap` (optional; refreshes cron schedules / runs bootstrap hooks, but does not start the server)

## Backups

This submenu provides backup and restore operations via the unified backup job.

Menu options:

1. `Restore from backup ZIP`
   - Lists available ZIP files (manual + scheduled).
   - Detects included components (`savegame`, `enshrouded_server.json`, `server_manager.json`).
   - Lets you select which components to restore.
   - Can optionally create a safety backup before restore.
2. `Create manual full backup now`
   - Runs a manual full backup (savegame + config includes according to backup job defaults).
3. `Create config backup now`
   - Offers:
     - Enshrouded config only
     - Server Manager config only
     - Both config files

Notes:

- ZIP backups are always created by the same backup job (`backup`), no matter if triggered manually, via cron, or as safety backup before restore.
- `BACKUP_MAX_COUNT` keeps the newest N zip backups and deletes older ones (nothing is overwritten). Manual/safety backups count toward the same limit.
- Config JSON backups under `BACKUP_DIR/profiles` are not affected by `BACKUP_MAX_COUNT`.

Example:

If `BACKUP_MAX_COUNT=7` and cron creates one backup per day, you will keep the newest 7 zip files. Creating extra manual/safety backups will still keep only 7 total zip files and may prune older daily backups sooner.

## Other Commands

This submenu is a convenience wrapper around existing `server` commands:

- `status`
- `scheduled-restart`
- `bootstrap`
- `cron sync`

Note: explicit reset commands are intentionally not listed here, because profile reset/apply is handled through the unified `profile` job and menu flows.

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

- change a value in the JSON editors (exactly one backup per edit session, created on the first write)
- apply a profile template (`Select and apply profile`)
- run profile reset/apply via menu flows (internally runs `server profile <target> <apply|reset> [profile]`)

Retention:

- Config backups are not automatically pruned. If you want retention, delete old files manually in `BACKUP_DIR/profiles`.

## Settings Precedence (Important)

Some settings can be provided via container environment variables (see `docs/environment.md`). If a value is set via env var, it is treated as the source of truth and may overwrite manual JSON edits when bootstrap runs.

Practical rule:

- If you want the menu-edited JSON to stay in control, avoid setting the same option via container environment values.

Behavior in the menu:

- The JSON editors show `[ENV]` next to locked fields and will block editing them.
- Before selecting a profile template, the menu shows a warning listing active env overrides and asks for confirmation.

## Troubleshooting

- If the menu looks broken or does not accept input:
  - Use `docker exec -it ...`
- If you change settings but they do not take effect:
  - Restart the server (`server restart`) or run bootstrap (`server bootstrap`)
