# Server Manager Configuration

This document includes:

- General manager settings
- Automation settings (ordered as in the config file)
- Hook fields and execution points
- [Example server_manager.json](../server_manager/profiles/manager/default_server_manager.json)

---

## General Server Manager Settings

| Setting | Description | Example / Default Value | Options / Notes |
|-------------------------------|---------------------------------------------|--------------------------|---------------------------|
| **puid** | Runtime UID for container user mapping | 4711 | Integer >= 1 (`PUID`) |
| **pgid** | Runtime GID for container user mapping | 4711 | Integer >= 1 (`PGID`) |
| **logColor** | Colored log output | true | true / false (`LOG_COLOR`) |
| **MANAGER_PROFILE** | Selected Server Manager profile name | "default" | Profile selector (`MANAGER_PROFILE`) |
| **EN_PROFILE** | Selected Enshrouded profile name | "default" | Profile selector (`EN_PROFILE`) |
| **actualProfilManager** | Persisted active manager profile | "default" | Updated by menu/profile flows |
| **actualProfilEnshrouded** | Persisted active enshrouded profile | "default" | Updated by menu/profile flows |
| **savefileName** | Base save/backup file name token | "3ad85aea" | A-Z a-z 0-9 . _ - (`SAVEFILE_NAME`) |
| **steamAppId** | Steam App ID used for updates | 2278520 | Integer >= 1 (`STEAM_APP_ID`) |
| **gameBranch** | Steam branch/channel | "public" | Single-line string (`GAME_BRANCH`) |
| **steamcmdArgs** | Extra SteamCMD arguments | "validate" | Single-line string (`STEAMCMD_ARGS`) |
| **winedebug** | Wine debug setting | "-all" | Single-line string (`WINEDEBUG`) |
| **updateCheckPlayers** | Only update if no players are online | false | true / false (`UPDATE_CHECK_PLAYERS`) |
| **restartCheckPlayers** | Only restart if no players are online | false | true / false (`RESTART_CHECK_PLAYERS`) |
| **restartDowntimeSeconds** | Delay between stop and start on restart | 5 | Integer >= 0 (`RESTART_DOWNTIME_SECONDS`) |
| **backupDir** | Base backup directory | "backups" | Relative or absolute path (`BACKUP_DIR`) |
| **backupMaxCount** | Max number of savegame ZIP backups (0 = unlimited) | 0 | Integer >= 0 (`BACKUP_MAX_COUNT`) |
| **backupScheduledIncludeEnshroudedConfig** | Include `enshrouded_server.json` in scheduled backups | true | true / false (`BACKUP_SCHEDULED_INCLUDE_ENSHROUDED_CONFIG`) |
| **backupScheduledIncludeServerManagerConfig** | Include `server_manager.json` in scheduled backups | true | true / false (`BACKUP_SCHEDULED_INCLUDE_SERVER_MANAGER_CONFIG`) |

### Profile and Runtime Explanation

- **MANAGER_PROFILE** and **EN_PROFILE** are selector inputs, mainly used on first bootstrap (fresh volume or missing config).
- **actualProfilManager** and **actualProfilEnshrouded** are persisted selections used by menu/profile workflows.
- **updateCheckPlayers** and **restartCheckPlayers** provide player-aware protection for update/restart operations.
- **backupMaxCount = 0** means unlimited savegame ZIP backups.

---

## Automation Settings (Ordered by Config)

| Setting | Description | Default Value | Min | Max | Options / Notes |
|----------------------------------|----------------------------------------------------------|------------------------|----------------------|----------------------|--------------------------------------------------------------|
| **backupPreHook** | Command hook before backup job | null | - | - | Single-line command or null (`BACKUP_PRE_HOOK`) |
| **backupPostHook** | Command hook after backup job | null | - | - | Single-line command or null (`BACKUP_POST_HOOK`) |
| **updateCron** | Cron schedule for update job | null | - | - | Cron expression or null (`UPDATE_CRON`) |
| **backupCron** | Cron schedule for backup job | null | - | - | Cron expression or null (`BACKUP_CRON`) |
| **restartCron** | Cron schedule for restart job | null | - | - | Cron expression or null (`RESTART_CRON`) |
| **bootstrapHook** | Generic bootstrap hook (legacy/simple alias) | null | - | - | Single-line command or null (`BOOTSTRAP_HOOK`) |
| **restorePreHook** | Command hook before restore flow | null | - | - | Single-line command or null (`RESTORE_PRE_HOOK`) |
| **restorePostHook** | Command hook after restore flow | null | - | - | Single-line command or null (`RESTORE_POST_HOOK`) |
| **profilePreHook** | Command hook before profile apply/reset | null | - | - | Single-line command or null (`PROFILE_PRE_HOOK`) |
| **profilePostHook** | Command hook after profile apply/reset | null | - | - | Single-line command or null (`PROFILE_POST_HOOK`) |
| **updatePreHook** | Command hook before update job | null | - | - | Single-line command or null (`UPDATE_PRE_HOOK`) |
| **updatePostHook** | Command hook after update job | null | - | - | Single-line command or null (`UPDATE_POST_HOOK`) |
| **restartPreHook** | Command hook before restart job | null | - | - | Single-line command or null (`RESTART_PRE_HOOK`) |
| **restartPostHook** | Command hook after restart job | null | - | - | Single-line command or null (`RESTART_POST_HOOK`) |
| **bootstrapPreHook** | Command hook before bootstrap job | null | - | - | Single-line command or null (`BOOTSTRAP_PRE_HOOK`) |
| **bootstrapPostHook** | Command hook after bootstrap job | null | - | - | Single-line command or null (`BOOTSTRAP_POST_HOOK`) |
| **serverPreHook** | Command hook before server start flow | null | - | - | Single-line command or null (`SERVER_PRE_HOOK`) |
| **serverPostHook** | Command hook after server stop flow | null | - | - | Single-line command or null (`SERVER_POST_HOOK`) |
| **serverCommandPreHook** | Command hook before `server` command dispatch | null | - | - | Single-line command or null (`SERVER_COMMAND_PRE_HOOK`) |
| **serverCommandPostHook** | Command hook after `server` command dispatch | null | - | - | Single-line command or null (`SERVER_COMMAND_POST_HOOK`) |
| **menuPreHook** | Command hook before interactive menu | null | - | - | Single-line command or null (`MENU_PRE_HOOK`) |
| **menuPostHook** | Command hook after interactive menu | null | - | - | Single-line command or null (`MENU_POST_HOOK`) |
| **passwordViewPreHook** | Command hook before password-view job | null | - | - | Single-line command or null (`PASSWORD_VIEW_PRE_HOOK`) |
| **passwordViewPostHook** | Command hook after password-view job | null | - | - | Single-line command or null (`PASSWORD_VIEW_POST_HOOK`) |

*`null` means the hook/schedule is disabled.*

---

## Hook Fields & Execution

### Hook Field Format

| Field | Description | Type | Example Value | Options / Notes |
|----------------------|-----------------------------------------------------------------------|---------|--------------------|--------------------------------------|
| **<job>PreHook** | Runs before the corresponding job/flow | String / null | "echo pre" | Single-line command |
| **<job>PostHook** | Runs after the corresponding job/flow | String / null | "echo post" | Single-line command |
| **bootstrapHook** | Generic bootstrap hook alias | String / null | "echo bootstrap" | Used as fallback if specific pre-hook is not set |
| **<job>Cron** | Cron trigger for scheduled jobs | String / null | "0 */6 * * *" | Valid cron expression |

---

### Defined Hook Points

| Hook Key | ENV Override | Runs When |
|-----------------------|------------------------------|---------------------------------------------|
| **backupPreHook** | `BACKUP_PRE_HOOK` | Before backup job |
| **backupPostHook** | `BACKUP_POST_HOOK` | After backup job |
| **restorePreHook** | `RESTORE_PRE_HOOK` | Before restore flow |
| **restorePostHook** | `RESTORE_POST_HOOK` | After restore flow |
| **profilePreHook** | `PROFILE_PRE_HOOK` | Before profile apply/reset |
| **profilePostHook** | `PROFILE_POST_HOOK` | After profile apply/reset |
| **updatePreHook** | `UPDATE_PRE_HOOK` | Before update job |
| **updatePostHook** | `UPDATE_POST_HOOK` | After update job |
| **restartPreHook** | `RESTART_PRE_HOOK` | Before restart job |
| **restartPostHook** | `RESTART_POST_HOOK` | After restart job |
| **bootstrapPreHook** | `BOOTSTRAP_PRE_HOOK` | Before bootstrap job |
| **bootstrapPostHook** | `BOOTSTRAP_POST_HOOK` | After bootstrap job |
| **serverPreHook** | `SERVER_PRE_HOOK` | Before server start flow |
| **serverPostHook** | `SERVER_POST_HOOK` | After server stop flow |
| **serverCommandPreHook** | `SERVER_COMMAND_PRE_HOOK` | Before generic `server` command dispatch |
| **serverCommandPostHook** | `SERVER_COMMAND_POST_HOOK` | After generic `server` command dispatch |
| **menuPreHook** | `MENU_PRE_HOOK` | Before opening interactive menu |
| **menuPostHook** | `MENU_POST_HOOK` | After closing interactive menu |
| **passwordViewPreHook** | `PASSWORD_VIEW_PRE_HOOK` | Before password-view job |
| **passwordViewPostHook** | `PASSWORD_VIEW_POST_HOOK` | After password-view job |

### Job and Schedule Notes

- `updateCron`, `backupCron`, and `restartCron` are optional cron schedules.
- If a cron field is `null`, that schedule is disabled.
- Hook commands run inside the container job runtime and should be idempotent where possible.

---

## Manager Runtime Logs

- Manager runtime logs are written to `<resolved-log-dir>/server_manager.log` (default: `/home/enshrouded/server/logs/server_manager.log`).
- Path resolution order: `ENSHROUDED_LOG_DIR` ENV -> `enshrouded_server.json` (`.logDirectory`) -> fallback `logs`.
- This file also includes the `supervisord` main log output.
- On bootstrap, if `server_manager.log` already exists and is non-empty, it is rotated to `<resolved-log-dir>/server_manager_backup/server_manager_<timestamp>.log`.
