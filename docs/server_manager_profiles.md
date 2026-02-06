# Server Manager Profiles

Profiles define the initial defaults that are written to `server_manager.json` when it is created for the first time. After creation, profiles are not re-applied; runtime precedence is ENV > `server_manager.json` > defaults.

Profile selection:
- `MANAGER_PROFILE` (ENV) if set and valid
- Otherwise `default`

Profile files (full `server_manager.json` shape):
- `default`: `../server_manager/profiles/default.json`
- `manual`: `../server_manager/profiles/manual.json`

## Default Profile

This profile defines the full default set of Server Manager values and acts as the baseline for comparisons.

JSON: `../server_manager/profiles/default.json`

Full settings:
| Setting | Value | Notes |
|---|---|---|
| `puid` | `null` | Unset; manager will try to detect from paths |
| `pgid` | `null` | Unset; manager will try to detect from paths |
| `noColor` | `null` | Colors enabled (when TTY) |
| `logLevel` | `info` | Info-level logging |
| `logContext` | `server_manager` | Logs labeled `server_manager` |
| `umask` | `027` | Default file modes 640/750 |
| `autoFixPerms` | `true` | Auto-fix ownership/permissions enabled |
| `autoFixDirMode` | `775` | Directories chmod 775 when auto-fix runs |
| `autoFixFileMode` | `664` | Files chmod 664 when auto-fix runs |
| `savefileName` | `3ad85aea` | Backup base name `3ad85aea` |
| `stopTimeout` | `60` | Stop waits up to 60s before escalation |
| `steamAppId` | `2278520` | Enshrouded app id |
| `gameBranch` | `public` | Uses Steam branch `public` |
| `steamcmdArgs` | `validate` | SteamCMD runs `app_update ... validate` |
| `winedebug` | `-all` | Wine debug output disabled |
| `autoUpdate` | `true` | Periodic update checks enabled |
| `autoUpdateInterval` | `1800` | Check every 1800s (30 min) |
| `autoUpdateOnBoot` | `true` | Update check on boot |
| `autoRestartOnUpdate` | `true` | Restart after update enabled |
| `autoRestart` | `true` | Auto-restart on exit enabled |
| `autoRestartDelay` | `10` | Wait 10s before auto-restart |
| `autoRestartMaxAttempts` | `0` | Unlimited restart attempts |
| `safeMode` | `true` | Skip update/restart if players unknown |
| `healthCheckInterval` | `300` | Health check every 300s |
| `healthCheckOnStart` | `true` | Run health check on start |
| `updateCheckPlayers` | `false` | Updates allowed even with players |
| `restartCheckPlayers` | `false` | Restarts allowed even with players |
| `a2sTimeout` | `2` | A2S timeout 2s |
| `a2sRetries` | `2` | A2S retries 2 |
| `a2sRetryDelay` | `1` | A2S retry delay 1s |
| `logToStdout` | `true` | Log streaming to stdout enabled |
| `logTailLines` | `200` | Tail 200 log lines |
| `logPollInterval` | `2` | Poll every 2s |
| `logFilePattern` | `*.log` | Only `*.log` files |
| `backupDir` | `backups` | Backups stored in `backups/` |
| `backupMaxCount` | `7` | Keep last 7 backups (older pruned) |
| `backupPreHook` | `null` | No pre-backup hook |
| `backupPostHook` | `null` | No post-backup hook |
| `enableCron` | `true` | Scheduling enabled |
| `updateCron` | `0 4 * * *` | Update daily at 04:00 |
| `backupCron` | `0 0 * * *` | Backup daily at 00:00 |
| `restartCron` | `0 3 * * *` | Restart daily at 03:00 |
| `bootstrapHook` | `null` | No bootstrap hook |
| `updatePreHook` | `null` | No update pre-hook |
| `updatePostHook` | `null` | No update post-hook |
| `restartPreHook` | `null` | No restart pre-hook |
| `restartPostHook` | `null` | No restart post-hook |
| `printGroupPasswords` | `true` | Print user group passwords on first config |

## Manual Profile

This profile disables automation and scheduling, but still defines the full Server Manager config for easier manual editing.

JSON: `../server_manager/profiles/manual.json`

Key differences to `default`:
| Setting | Value | Notes |
|---|---|---|
| `AUTO_UPDATE` | `false` | No periodic update checks |
| `AUTO_UPDATE_ON_BOOT` | `false` | No update on boot |
| `AUTO_RESTART_ON_UPDATE` | `false` | No restart after update |
| `AUTO_RESTART` | `false` | No auto-restart on exit |
| `ENABLE_CRON` | `false` | Scheduling disabled |
| `UPDATE_CRON` | `null` | No update schedule |
| `BACKUP_CRON` | `null` | No backup schedule |
| `RESTART_CRON` | `null` | No restart schedule |
