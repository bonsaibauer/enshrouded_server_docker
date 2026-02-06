# Environment Variables

This document lists all environment variables you can pass via `docker run -e ...` that are referenced by the `Dockerfile` and the `server_manager` scripts.

Unless noted otherwise, leaving a variable unset means the manager will use the values from `enshrouded_server.json` (or its built-in defaults when it creates the file).

---

## Dockerfile Defaults

These are the `ENV` defaults baked into `Dockerfile`. You can override them at runtime with `docker run -e`.

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **DEBIAN_FRONTEND** | Noninteractive apt behavior | "noninteractive" | Affects apt; usually keep default |
| **LANG** | Locale | "en_US.UTF-8" | Locale string |
| **LANGUAGE** | Locale languages | "en_US:en" | Locale list |
| **LC_ALL** | Locale override | "en_US.UTF-8" | Locale string |
| **STEAM_APP_ID** | Steam app id for Enshrouded | "2278520" | Must match Enshrouded server app id |
---

## Server Manager Core (ENSHROUDED_)

These map directly to fields in `enshrouded_server.json`.

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **ENSHROUDED_NAME** | Server name | "Enshrouded Server" | Any string |
| **ENSHROUDED_SAVE_DIR** | Savegame directory (relative to `INSTALL_PATH` if not absolute) | "./savegame" | Path |
| **ENSHROUDED_LOG_DIR** | Log directory (relative to `INSTALL_PATH` if not absolute) | "./logs" | Path |
| **ENSHROUDED_IP** | Bind IP | "0.0.0.0" | IPv4 address |
| **ENSHROUDED_QUERY_PORT** | Query port | 15637 | 1-65535 |
| **ENSHROUDED_SLOT_COUNT** | Max players | 16 | 1-16 |
| **ENSHROUDED_TAGS** | Server browser tags | "" (unset) | Comma-separated; characters `[A-Za-z0-9._-]` |
| **ENSHROUDED_VOICE_CHAT_MODE** | Voice chat mode | "Proximity" | Proximity / Global |
| **ENSHROUDED_ENABLE_VOICE_CHAT** | Enable voice chat | false | true / false |
| **ENSHROUDED_ENABLE_TEXT_CHAT** | Enable text chat | false | true / false |

---

## Server Manager User Groups (ENSHROUDED_ROLE_<index>_*)

Use `<index>` starting at `0` (e.g., `ENSHROUDED_ROLE_0_NAME`). When set, these override or create user groups in the JSON.

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **ENSHROUDED_ROLE_<index>_NAME** | Group name | "Admin" | Any string |
| **ENSHROUDED_ROLE_<index>_PASSWORD** | Group password | "AdminXXXXXXXX" | Any string |
| **ENSHROUDED_ROLE_<index>_CAN_KICK_BAN** | Can kick/ban | true | true / false |
| **ENSHROUDED_ROLE_<index>_CAN_ACCESS_INVENTORIES** | Access other inventories | true | true / false |
| **ENSHROUDED_ROLE_<index>_CAN_EDIT_WORLD** | Edit world outside bases | true | true / false |
| **ENSHROUDED_ROLE_<index>_CAN_EDIT_BASE** | Edit any base | true | true / false |
| **ENSHROUDED_ROLE_<index>_CAN_EXTEND_BASE** | Extend base territory | true | true / false |
| **ENSHROUDED_ROLE_<index>_RESERVED_SLOTS** | Reserved slots for group | 0 | Integer |

---

## Server Manager Gameplay Settings (ENSHROUDED_GS_)

These map to `gameSettings` and `gameSettingsPreset` in the JSON. Values are only applied if the env var is set.

| Variable | Description | Default Value | Min | Max | Options / Notes |
|---------|-------------|---------------|-----|-----|----------------|
| **ENSHROUDED_GS_PRESET** | Preset for gameplay settings | Default | - | - | Default / Relaxed / Hard / Survival / Custom |
| **ENSHROUDED_GS_PLAYER_HEALTH_FACTOR** | Player max health factor | 1 | 0.25 | 4 | Numeric |
| **ENSHROUDED_GS_PLAYER_MANA_FACTOR** | Player max mana factor | 1 | 0.25 | 4 | Numeric |
| **ENSHROUDED_GS_PLAYER_STAMINA_FACTOR** | Player max stamina factor | 1 | 0.25 | 4 | Numeric |
| **ENSHROUDED_GS_PLAYER_BODY_HEAT_FACTOR** | Body heat pool factor | 1 | 0.5 | 2 | 0.5 / 1 / 1.5 / 2 |
| **ENSHROUDED_GS_PLAYER_DIVING_TIME_FACTOR** | Diving time factor | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_ENABLE_DURABILITY** | Weapon/tool durability | true | - | - | true / false |
| **ENSHROUDED_GS_ENABLE_STARVING_DEBUFF** | Starving debuff | false | - | - | true / false |
| **ENSHROUDED_GS_FOOD_BUFF_DURATION_FACTOR** | Food buff duration factor | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_FROM_HUNGER_TO_STARVING** | Hungry to starving (ns) | 600000000000 | 300000000000 | 1200000000000 | Nanoseconds |
| **ENSHROUDED_GS_SHROUD_TIME_FACTOR** | Shroud time factor | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_TOMBSTONE_MODE** | Items lost on death | AddBackpackMaterials | - | - | AddBackpackMaterials / Everything / NoTombstone |
| **ENSHROUDED_GS_ENABLE_GLIDER_TURBULENCES** | Glider turbulences | true | - | - | true / false |
| **ENSHROUDED_GS_WEATHER_FREQUENCY** | Weather frequency | Normal | - | - | Disabled / Rare / Normal / Often |
| **ENSHROUDED_GS_FISHING_DIFFICULTY** | Fishing difficulty | Normal | - | - | VeryEasy / Easy / Normal / Hard / VeryHard |
| **ENSHROUDED_GS_MINING_DAMAGE_FACTOR** | Mining damage factor | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_PLANT_GROWTH_SPEED_FACTOR** | Plant growth speed | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_RESOURCE_DROP_STACK_AMOUNT_FACTOR** | Resource drop stack factor | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_FACTORY_PRODUCTION_SPEED_FACTOR** | Factory production speed | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_PERK_UPGRADE_RECYCLING_FACTOR** | Perk upgrade recycling | 0.5 | 0 | 1 | Numeric |
| **ENSHROUDED_GS_PERK_COST_FACTOR** | Perk cost factor | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_EXPERIENCE_COMBAT_FACTOR** | Combat XP factor | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_EXPERIENCE_MINING_FACTOR** | Mining XP factor | 1 | 0 | 2 | Numeric |
| **ENSHROUDED_GS_EXPERIENCE_EXPLORATION_QUESTS_FACTOR** | Exploration/quests XP factor | 1 | 0.25 | 2 | Numeric |
| **ENSHROUDED_GS_RANDOM_SPAWNER_AMOUNT** | Ambient enemy density | Normal | - | - | Few / Normal / Many / Extreme |
| **ENSHROUDED_GS_AGGRO_POOL_AMOUNT** | Simultaneous attackers | Normal | - | - | Few / Normal / Many / Extreme |
| **ENSHROUDED_GS_ENEMY_DAMAGE_FACTOR** | Enemy damage factor | 1 | 0.25 | 5 | Numeric |
| **ENSHROUDED_GS_ENEMY_HEALTH_FACTOR** | Enemy health factor | 1 | 0.25 | 4 | Numeric |
| **ENSHROUDED_GS_ENEMY_STAMINA_FACTOR** | Enemy stamina factor | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_ENEMY_PERCEPTION_RANGE_FACTOR** | Enemy perception range | 1 | 0.5 | 2 | Numeric |
| **ENSHROUDED_GS_BOSS_DAMAGE_FACTOR** | Boss damage factor | 1 | 0.2 | 5 | Numeric |
| **ENSHROUDED_GS_BOSS_HEALTH_FACTOR** | Boss health factor | 1 | 0.2 | 5 | Numeric |
| **ENSHROUDED_GS_THREAT_BONUS** | Enemy attack frequency | 1 | 0.25 | 4 | Numeric |
| **ENSHROUDED_GS_PACIFY_ALL_ENEMIES** | Enemies attack only when provoked | false | - | - | true / false |
| **ENSHROUDED_GS_TAMING_STARTLE_REPERCUSSION** | Taming startle penalty | LoseSomeProgress | - | - | KeepProgress / LoseSomeProgress / LoseAllProgress |
| **ENSHROUDED_GS_DAY_TIME_DURATION** | Daytime length (ns) | 1800000000000 | 120000000000 | 3600000000000 | Nanoseconds |
| **ENSHROUDED_GS_NIGHT_TIME_DURATION** | Nighttime length (ns) | 720000000000 | 120000000000 | 3600000000000 | Nanoseconds |
| **ENSHROUDED_GS_CURSE_MODIFIER** | Shroud curse chance | Normal | - | - | Easy / Normal / Hard |

*Time-based values are stored in nanoseconds. Divide by 60,000,000,000 to convert to minutes.*

---

## Server Manager Runtime

The manager also reads (and creates if missing) `server_manager.json` next to `enshrouded_server.json`. Values are applied in this order: ENV > `server_manager.json` > defaults. Invalid manager ENV values are warned and ignored. `PUID`/`PGID` can be set in `server_manager.json`; if they are missing, the manager tries to detect them from `INSTALL_PATH`, the config directory, or `HOME`.

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **PUID** | User ID for `steam` user mapping | (required) | Must be numeric and not 0 |
| **PGID** | Group ID for `steam` user mapping | (required) | Must be numeric and not 0 |
| **NO_COLOR** | Disable ANSI colors | unset | Set to any value to disable |
| **LOG_LEVEL** | Log verbosity | "info" | debug / info / warn / error |
| **LOG_CONTEXT** | Log context label | "server_manager" | Internal |
| **UMASK** | Default umask | "027" | Octal string |
| **AUTO_FIX_PERMS** | Auto-fix ownership/permissions on key dirs | true | true / false |
| **AUTO_FIX_DIR_MODE** | chmod mode for directories when auto-fix runs | "775" | Octal string |
| **AUTO_FIX_FILE_MODE** | chmod mode for files when auto-fix runs | "664" | Octal string |
| **SAVEFILE_NAME** | Savefile base name | "3ad85aea" | Used for backups |
| **STOP_TIMEOUT** | Shutdown timeout (seconds) | 60 | Integer seconds |

---

## Steam / Proton

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **STEAM_APP_ID** | Steam app id | "2278520" | Must match Enshrouded server |
| **GAME_BRANCH** | Steam branch | "public" | e.g., `public`, `experimental` |
| **STEAMCMD_ARGS** | SteamCMD args | "validate" | Passed to `app_update` |
| **WINEDEBUG** | Wine debug flags | "-all" | Optional; set to adjust output |

---

## Updates, Restarts, Health Checks

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **AUTO_UPDATE** | Enable periodic update checks | true | true / false |
| **AUTO_UPDATE_INTERVAL** | Update interval (seconds) | 1800 | Integer seconds |
| **AUTO_UPDATE_ON_BOOT** | Update on manager start | true | true / false |
| **AUTO_RESTART_ON_UPDATE** | Restart after update | true | true / false |
| **AUTO_RESTART** | Auto-restart if server exits | true | true / false |
| **AUTO_RESTART_DELAY** | Delay before restart (seconds) | 10 | Integer seconds |
| **AUTO_RESTART_MAX_ATTEMPTS** | Max restart attempts | 0 | 0 = unlimited |
| **SAFE_MODE** | Skip update/restart if player count unknown | true | true / false |
| **HEALTH_CHECK_INTERVAL** | Health check interval (seconds) | 300 | 0 disables checks |
| **HEALTH_CHECK_ON_START** | Health check on start | true | true / false |
| **UPDATE_CHECK_PLAYERS** | Require 0 players before update | false | true / false |
| **RESTART_CHECK_PLAYERS** | Require 0 players before restart | false | true / false |
| **A2S_TIMEOUT** | A2S query timeout (seconds) | 2 | Float |
| **A2S_RETRIES** | A2S query retries | 2 | Integer |
| **A2S_RETRY_DELAY** | Delay between A2S retries (seconds) | 1 | Float |

---

## Logging

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **LOG_TO_STDOUT** | Stream logs to stdout | true | true / false |
| **LOG_TAIL_LINES** | Tail lines per log file | 200 | Integer |
| **LOG_POLL_INTERVAL** | Log file poll interval (seconds) | 2 | Integer seconds |
| **LOG_FILE_PATTERN** | Log file glob | "*.log" | Used by `find -name` |

---

## Backups

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **BACKUP_DIR** | Backup directory | "backups" | Relative to `INSTALL_PATH` if not absolute |
| **BACKUP_MAX_COUNT** | Max backups to keep | 0 | 0 = keep all |
| **BACKUP_PRE_HOOK** | Command before backup | unset | Executed with `eval` |
| **BACKUP_POST_HOOK** | Command after backup | unset | Executed with `eval` |

---

## Scheduling (Cron)

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **ENABLE_CRON** | Enable cron support | true | true / false |
| **UPDATE_CRON** | Cron schedule for update | "0 */6 * * *" | Standard cron format |
| **BACKUP_CRON** | Cron schedule for backup | "0 */12 * * *" | Standard cron format |
| **RESTART_CRON** | Cron schedule for restart | "0 5 * * *" | Standard cron format |

---

## Hooks

| Variable | Description | Example / Default Value | Options / Notes |
|---------|-------------|--------------------------|-----------------|
| **BOOTSTRAP_HOOK** | Command after setup/bootstrapping | unset | Executed with `eval` |
| **UPDATE_PRE_HOOK** | Command before update | unset | Executed with `eval` |
| **UPDATE_POST_HOOK** | Command after update | unset | Executed with `eval` |
| **RESTART_PRE_HOOK** | Command before restart | unset | Executed with `eval` |
| **RESTART_POST_HOOK** | Command after restart | unset | Executed with `eval` |
| **PRINT_ADMIN_PASSWORD** | Print generated admin password on first config creation | true | true / false |

---

