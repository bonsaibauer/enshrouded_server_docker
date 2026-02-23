# Interactive Shell Menu (`menu`)

The interactive menu is the recommended control center for daily operations, profile handling, and editing both runtime JSON configs.

## Run

The menu requires a TTY. Always use `-it`.

Replace `enshroudedserver` with your container name (see `docker ps`).

```bash
docker exec -it enshroudedserver menu
```

Optional arguments (from the menu CLI):

- `--screen <id>` starts directly on a specific screen.
- `--once` runs one menu cycle and exits.
- `--no-clear` keeps terminal output without screen clearing.

Compatibility alias (same menu):

```bash
docker exec -it enshroudedserver server menu
```

## Selection Menu Preview

![Server Menu Selection Menu](../images/menu.png)

Top-level selections:

1. `Enshrouded Server Settings`
2. `Server Manager Settings`
3. `Backup Menu`
4. `Start/Stop/Restart/Update/update_force/View Passwords/Create Manual Backup`
5. `Other Commands` (`status`, `scheduled-restart`, `bootstrap`, `cron sync`)

## Navigation

- Enter a number (or `b`/`m`/`x`) and press Enter.
- `b` = Back in submenus (`b` in main menu exits).
- `m` = Main Menu.
- `x` = Exit menu.
- Prompts use `yes/no` (also accepts `y/n`).
- `[ENV]` marks settings controlled by container environment variables (locked in the editors).

Logging:

- Menu uses the same levels as the job scripts: `info`, `warn`, `error`, `success`, `fatal`.
- Logging functions are defined centrally in `server_manager/jobs/server` and imported by all job scripts.
- `info`: neutral runtime hints and progress messages (for example navigation/help text, "running command").
- `success`: completed actions.
- `warn`: non-critical problems, invalid input, or constraints where the current step can still continue.
- `error`: action failed, but the interactive flow continues (for example backup/restore failure or invalid config in an editor flow).
- `fatal`: unrecoverable menu state (for example missing/invalid menu spec) and aborts the current menu run.
- Menu messages are shown in the interactive UI and are also written to job logging (`docker logs`) with the same level.

Exit behavior:

- If `server` is `STOPPED` when you exit, the menu asks whether it should be started before closing.
- If confirmed, the menu runs the unified `bootstrap + start` flow.

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
- `Start Server` runs `bootstrap + start`.
- `Stop Server` and `Restart Server` require a currently running server.
- `update_force` maps to `docker exec enshroudedserver update force`.
- `update_force` asks for an extra confirmation in the menu.
- The quick actions are the same command family as:
  - `docker exec enshroudedserver start`
  - `docker exec enshroudedserver stop`
  - `docker exec enshroudedserver restart`
  - `docker exec enshroudedserver update`
  - `docker exec enshroudedserver password-view`

## Current Change Workflow

Use this order for config changes in menu:

1. Open menu: `docker exec -it enshroudedserver menu`
2. Edit or apply/reset profile in the matching submenu.
3. After profile apply/reset, the menu offers `Bootstrap + start Enshrouded server` directly.
4. For edit-only flows, let menu run `bootstrap + start` on exit (if stopped), or run manually:
   - `docker exec enshroudedserver bootstrap`
   - `docker exec enshroudedserver start`

## Enshrouded Server Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/enshrouded_server.json` (persistent volume file).
   - If server is running, menu asks to stop `server` before editing.
   - Changes are written immediately (no explicit save step).
   - Includes dedicated editing for:
     - `gameSettings`
     - `userGroups`
   - Validates ports, slot count, booleans, tags, ranges, and enums.

2. `Reset current profile`
   - Replaces active config with currently selected profile.
   - Menu confirms and stops `server` first (if running).
   - Disabled in menu if `EN_PROFILE` is set via container ENV.

3. `Select and apply profile`
   - Lists profile templates from `EN_PROFILE_DIR` (default: `/home/enshrouded/server/profiles/enshrouded/`).
   - Applies selected template to `/home/enshrouded/server/enshrouded_server.json`.
   - Preserves existing ban lists (`.bannedAccounts` and legacy `.bans`) during apply/reset.
   - Disabled in menu if `EN_PROFILE` is set via container ENV.

4. `Manage Banned Accounts`
   - Lists merged entries from `.bannedAccounts` and legacy `.bans`.
   - Supports `deban`/unban by selection.
   - Removes the selected account from both ban arrays for compatibility.
   - This menu flow does not create new bans; it is an unban/remove-ban workflow.

## Server Manager Settings

1. `Edit current settings`
   - Edits `/home/enshrouded/server/server_manager/server_manager.json`.
   - If server is running, menu asks to stop `server` before editing.
   - Changes are written immediately (no explicit save step).

2. `Reset current profile`
   - Replaces active config with currently selected manager profile.
   - Menu confirms and stops `server` first (if running).
   - Disabled in menu if `MANAGER_PROFILE` is set via container ENV.

3. `Select and apply profile`
   - Lists templates from `MANAGER_PROFILE_DIR` (default: `/home/enshrouded/server/profiles/manager/`).
   - Applies selected template to `/home/enshrouded/server/server_manager/server_manager.json`.
   - Disabled in menu if `MANAGER_PROFILE` is set via container ENV.

## Backups

The Backup submenu uses one unified backup engine for manual, scheduled, and restore safety backups.

Menu options:

1. `Restore from backup ZIP`
   - Lists ZIP files (manual + scheduled).
   - Detects included parts (`savegame`, `enshrouded_server.json`, `server_manager.json`).
   - Lets you restore selected parts only.
   - Can create a safety backup before restore.
   - If no ZIP exists, menu can create a manual backup first.
2. `Create manual full backup now`
   - Runs a manual full backup.
3. `Create config backup now`
   - Enshrouded config only, manager config only, or both.

Notes:

- Manual backups (including config-only menu backups) are written to `BACKUP_DIR/manual`.
- Scheduled backups are written to `BACKUP_DIR/scheduled`.
- `BACKUP_MAX_COUNT` cleanup applies to scheduled backups only.
- Manual backups are not pruned by `backupMaxCount`.

## Other Commands

This submenu is a shortcut for:

- `status`
- `scheduled-restart`
- `bootstrap`
- `cron sync`

## Profile Selection Persistence

Selected profiles are persisted in:

- `/home/enshrouded/server/server_manager/server_manager.json`

Keys:

- `actualProfilManager`
- `actualProfilEnshrouded`

Initial selectors are captured from ENV:

- `MANAGER_PROFILE`
- `EN_PROFILE`

`EN_PROFILE` / `MANAGER_PROFILE` are used directly only when no persisted selectors exist yet (fresh volume or missing config).

## Config Backups (Automatic)

Whenever menu writes or replaces config files, it creates timestamped backup ZIP files in:

- `BACKUP_DIR/manual`

Default path (`backupDir = "backups"`):

- `/home/enshrouded/server/backups/manual`

Created when:

- changing values in JSON editors (one backup on first write in an edit session)
- applying a profile template
- running reset/apply menu flows

Retention:

- Backups in `BACKUP_DIR/manual` are not auto-pruned by `backupMaxCount`.

## Settings Precedence

If a setting is provided via container ENV (see `docs/environment.md`), ENV is treated as source of truth and can overwrite manual JSON edits during bootstrap.

Practical rule:

- If you want JSON-edited values to stay active, do not set the same keys via container ENV.

Menu behavior:

- Editors show `[ENV]` on locked fields and block edits there.
- Profile apply flow warns when active ENV overrides exist.
- Profile apply/reset is disabled when selector ENV is set (`EN_PROFILE` or `MANAGER_PROFILE`).

## Troubleshooting

- Menu input not working:
  - Use `docker exec -it enshroudedserver menu`.
- Settings changed but effect missing:
  - Run `docker exec enshroudedserver bootstrap` then `docker exec enshroudedserver start`.
