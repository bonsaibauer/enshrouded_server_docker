# Environment Variables

Diese Datei dokumentiert die aktuell verwendeten ENV-Variablen des heutigen `server_manager`-Setups.

Reihenfolge der Werteauflösung:
1. ENV
2. Laufzeitdateien (`/home/enshrouded/server/server_manager/server_manager.json`, `/home/enshrouded/server/enshrouded_server.json`)
3. Profil-Templates (nur bei Initialisierung)

## Profilauswahl

| Variable | Beschreibung | Default |
|---|---|---|
| `MANAGER_PROFILE` | Wählt das Manager-Profil (Template) | `default` |
| `EN_PROFILE` | Wählt das Enshrouded-Profil (Template) | `default` |

## Manager-Variablen

Diese Variablen werden aktiv über `server_manager/shared/profile` geladen.

| Variable | Typ | Default | Zweck |
|---|---:|---|---|
| `PUID` | int | `4711` | UID für `enshrouded` |
| `PGID` | int | `4711` | GID für `enshrouded` |
| `LOG_COLOR` | bool | `true` | Farbige Log-Level (nur bei TTY) |
| `SAVEFILE_NAME` | string | `3ad85aea` | Basisname für Save/Backup |
| `STEAM_APP_ID` | int | `2278520` | Steam App ID |
| `GAME_BRANCH` | string | `public` | Steam Branch |
| `STEAMCMD_ARGS` | string | `validate` | Zusätzliche SteamCMD-Args |
| `WINEDEBUG` | string | `-all` | Wine Debug-Level |
| `UPDATE_CHECK_PLAYERS` | bool | `false` | Update nur bei 0 Spielern |
| `RESTART_CHECK_PLAYERS` | bool | `false` | Restart nur bei 0 Spielern |
| `BACKUP_DIR` | string | `backups` | Backup-Zielordner |
| `BACKUP_MAX_COUNT` | int | `0` | Anzahl Backups (`0` = unbegrenzt) |
| `BACKUP_PRE_HOOK` | string | `null` | Hook vor Backup |
| `BACKUP_POST_HOOK` | string | `null` | Hook nach Backup |
| `UPDATE_CRON` | string | `null` | Cron für Update-Job |
| `BACKUP_CRON` | string | `null` | Cron für Backup-Job |
| `RESTART_CRON` | string | `null` | Cron für Restart-Job |
| `BOOTSTRAP_HOOK` | string | `null` | Hook im Bootstrap |
| `UPDATE_PRE_HOOK` | string | `null` | Hook vor Update |
| `UPDATE_POST_HOOK` | string | `null` | Hook nach Update |
| `RESTART_PRE_HOOK` | string | `null` | Hook vor Restart |
| `RESTART_POST_HOOK` | string | `null` | Hook nach Restart |

## Enshrouded-Server Variablen

Diese Variablen landen in `enshrouded_server.json`.

| Variable | Typ | Default |
|---|---:|---|
| `ENSHROUDED_NAME` | string | `Enshrouded Server` |
| `ENSHROUDED_SAVE_DIR` | string | `./savegame` |
| `ENSHROUDED_LOG_DIR` | string | `./logs` |
| `ENSHROUDED_IP` | string | `0.0.0.0` |
| `ENSHROUDED_QUERY_PORT` | int | `15637` |
| `ENSHROUDED_SLOT_COUNT` | int | `16` |
| `ENSHROUDED_TAGS` | string | leer |
| `ENSHROUDED_VOICE_CHAT_MODE` | enum | `Proximity` |
| `ENSHROUDED_ENABLE_VOICE_CHAT` | bool | `false` |
| `ENSHROUDED_ENABLE_TEXT_CHAT` | bool | `false` |

## Rollen-Variablen

Schema: `ENSHROUDED_ROLE_<index>_<FIELD>`

| Feld | Typ |
|---|---:|
| `NAME` | string |
| `PASSWORD` | string |
| `CAN_KICK_BAN` | bool |
| `CAN_ACCESS_INVENTORIES` | bool |
| `CAN_EDIT_WORLD` | bool |
| `CAN_EDIT_BASE` | bool |
| `CAN_EXTEND_BASE` | bool |
| `RESERVED_SLOTS` | int |

## Gameplay-Variablen

Schema: `ENSHROUDED_GS_*` (vollständig validiert in `server_manager/shared/env`).

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

## Zusätzliche CLI-Variable

| Variable | Beschreibung | Default |
|---|---|---|
| `SUPERVISORCTL_BIN` | Binary für `ctl` Wrapper | `supervisorctl` |
