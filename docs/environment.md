# Environment Variables

This file documents the environment variables used by the current `server_manager` setup.

Value resolution order:
1. ENV
2. Runtime files (`/home/enshrouded/server/server_manager/server_manager.json`, `/home/enshrouded/server/enshrouded_server.json`)
3. Profile templates (only during initialization)

## Profile Selection

| Variable | Description | Default |
|---|---|---|
| `MANAGER_PROFILE` | Selects the manager profile (template) | `default` |
| `EN_PROFILE` | Selects the Enshrouded profile (template) | `default` |

## Manager Variables

These variables are actively loaded via `server_manager/shared/profile`.

| Variable | Type | Default | Purpose |
|---|---:|---|---|
| `PUID` | int | `4711` | UID for `enshrouded` |
| `PGID` | int | `4711` | GID for `enshrouded` |
| `LOG_COLOR` | bool | `true` | Colored log levels (TTY only) |
| `SAVEFILE_NAME` | string | `3ad85aea` | Base name for save/backup |
| `STEAM_APP_ID` | int | `2278520` | Steam App ID |
| `GAME_BRANCH` | string | `public` | Steam Branch |
| `STEAMCMD_ARGS` | string | `validate` | Additional SteamCMD args |
| `WINEDEBUG` | string | `-all` | Wine debug level |
| `UPDATE_CHECK_PLAYERS` | bool | `false` | Only update when 0 players are connected |
| `RESTART_CHECK_PLAYERS` | bool | `false` | Only restart when 0 players are connected |
| `BACKUP_DIR` | string | `backups` | Backup target directory |
| `BACKUP_MAX_COUNT` | int | `0` | Number of backups (`0` = unlimited) |
| `BACKUP_PRE_HOOK` | string | `null` | Hook before backup |
| `BACKUP_POST_HOOK` | string | `null` | Hook after backup |
| `UPDATE_CRON` | string | `null` | Cron schedule for update job |
| `BACKUP_CRON` | string | `null` | Cron schedule for backup job |
| `RESTART_CRON` | string | `null` | Cron schedule for restart job |
| `BOOTSTRAP_HOOK` | string | `null` | Hook executed during bootstrap |
| `UPDATE_PRE_HOOK` | string | `null` | Hook before update |
| `UPDATE_POST_HOOK` | string | `null` | Hook after update |
| `RESTART_PRE_HOOK` | string | `null` | Hook before restart |
| `RESTART_POST_HOOK` | string | `null` | Hook after restart |

## Enshrouded Server Variables

These variables are written to `enshrouded_server.json`.

| Variable | Typ | Default |
|---|---:|---|
| `ENSHROUDED_NAME` | string | `Enshrouded Server` |
| `ENSHROUDED_SAVE_DIR` | string | `./savegame` |
| `ENSHROUDED_LOG_DIR` | string | `./logs` |
| `ENSHROUDED_IP` | string | `0.0.0.0` |
| `ENSHROUDED_QUERY_PORT` | int | `15637` |
| `ENSHROUDED_SLOT_COUNT` | int | `16` |
| `ENSHROUDED_TAGS` | string | empty |
| `ENSHROUDED_VOICE_CHAT_MODE` | enum | `Proximity` |
| `ENSHROUDED_ENABLE_VOICE_CHAT` | bool | `false` |
| `ENSHROUDED_ENABLE_TEXT_CHAT` | bool | `false` |

## Role Variables

Schema: `ENSHROUDED_ROLE_<index>_<FIELD>`

| Field | Type |
|---|---:|
| `NAME` | string |
| `PASSWORD` | string |
| `CAN_KICK_BAN` | bool |
| `CAN_ACCESS_INVENTORIES` | bool |
| `CAN_EDIT_WORLD` | bool |
| `CAN_EDIT_BASE` | bool |
| `CAN_EXTEND_BASE` | bool |
| `RESERVED_SLOTS` | int |

## Gameplay Variables

Schema: `ENSHROUDED_GS_*` (fully validated in `server_manager/shared/env`).

- `ENSHROUDED_GS_PRESET`
- `ENSHROUDED_GS_PLAYER_HEALTH_FACTOR`
- `ENSHROUDED_GS_PLAYER_MANA_FACTOR`
- `ENSHROUDED_GS_PLAYER_STAMINA_FACTOR`
- `ENSHROUDED_GS_PLAYER_BODY_HEAT_FACTOR`
- `ENSHROUDED_GS_PLAYER_DIVING_TIME_FACTOR`
- `ENSHROUDED_GS_ENABLE_DURABILITY`
- `ENSHROUDED_GS_ENABLE_STARVING_DEBUFF`
- `ENSHROUDED_GS_FOOD_BUFF_DURATION_FACTOR`
- `ENSHROUDED_GS_FROM_HUNGER_TO_STARVING`
- `ENSHROUDED_GS_SHROUD_TIME_FACTOR`
- `ENSHROUDED_GS_TOMBSTONE_MODE`
- `ENSHROUDED_GS_ENABLE_GLIDER_TURBULENCES`
- `ENSHROUDED_GS_WEATHER_FREQUENCY`
- `ENSHROUDED_GS_FISHING_DIFFICULTY`
- `ENSHROUDED_GS_MINING_DAMAGE_FACTOR`
- `ENSHROUDED_GS_PLANT_GROWTH_SPEED_FACTOR`
- `ENSHROUDED_GS_RESOURCE_DROP_STACK_AMOUNT_FACTOR`
- `ENSHROUDED_GS_FACTORY_PRODUCTION_SPEED_FACTOR`
- `ENSHROUDED_GS_PERK_UPGRADE_RECYCLING_FACTOR`
- `ENSHROUDED_GS_PERK_COST_FACTOR`
- `ENSHROUDED_GS_EXPERIENCE_COMBAT_FACTOR`
- `ENSHROUDED_GS_EXPERIENCE_MINING_FACTOR`
- `ENSHROUDED_GS_EXPERIENCE_EXPLORATION_QUESTS_FACTOR`
- `ENSHROUDED_GS_RANDOM_SPAWNER_AMOUNT`
- `ENSHROUDED_GS_AGGRO_POOL_AMOUNT`
- `ENSHROUDED_GS_ENEMY_DAMAGE_FACTOR`
- `ENSHROUDED_GS_ENEMY_HEALTH_FACTOR`
- `ENSHROUDED_GS_ENEMY_STAMINA_FACTOR`
- `ENSHROUDED_GS_ENEMY_PERCEPTION_RANGE_FACTOR`
- `ENSHROUDED_GS_BOSS_DAMAGE_FACTOR`
- `ENSHROUDED_GS_BOSS_HEALTH_FACTOR`
- `ENSHROUDED_GS_THREAT_BONUS`
- `ENSHROUDED_GS_PACIFY_ALL_ENEMIES`
- `ENSHROUDED_GS_TAMING_STARTLE_REPERCUSSION`
- `ENSHROUDED_GS_DAY_TIME_DURATION`
- `ENSHROUDED_GS_NIGHT_TIME_DURATION`
- `ENSHROUDED_GS_CURSE_MODIFIER`

## Additional CLI Variable

| Variable | Description | Default |
|---|---|---|
| `SUPERVISORCTL_BIN` | Binary for the `ctl` wrapper | `supervisorctl` |
