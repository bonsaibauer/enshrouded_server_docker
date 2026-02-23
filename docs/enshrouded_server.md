# Enshrouded Server Configuration

This document includes:

- General server settings
- Gameplay settings (ordered as in the config file)
- User group permissions
- [Example enshrouded_server.json](../server_manager/profiles/enshrouded/default_enshrouded_server.json)

---

## General Server Settings

| Setting | Description | Example / Default Value | Options / Notes |
|--------------------|--------------------------------------------|--------------------------|---------------------------|
| **name** | Name of the server | "Enshrouded Server" | Any string (`ENSHROUDED_NAME`) |
| **saveDirectory** | Directory where savegames are stored | "./savegame" | File path (`ENSHROUDED_SAVE_DIR`) |
| **logDirectory** | Directory for log files | "./logs" | File path (`ENSHROUDED_LOG_DIR`). Also hosts `server_manager.log` and `server_manager_backup/`. |
| **ip** | Server IP binding | "0.0.0.0" | Server IPv4 address (`ENSHROUDED_IP`) |
| **queryPort** | Port used for server queries | 15637 | Integer 1..65535 (`ENSHROUDED_QUERY_PORT`, `env_mode=deferred`: can initialize from ENV or config/profile fallback at runtime). |
| **slotCount** | Max number of players | 16 | Integer 1..16 (`ENSHROUDED_SLOT_COUNT`) |
| **tags** | Optional server browser tags | [] | Comma-separated tags in ENV (`ENSHROUDED_TAGS`), each tag: `A-Z a-z 0-9 . _ -` |
| **voiceChatMode** | Voice chat type | Proximity | Proximity / Global (`ENSHROUDED_VOICE_CHAT_MODE`) |
| **enableVoiceChat** | Enable/disable voice chat | false | true / false (`ENSHROUDED_ENABLE_VOICE_CHAT`) |
| **enableTextChat** | Enable/disable text chat | false | true / false (`ENSHROUDED_ENABLE_TEXT_CHAT`) |
| **gameSettingsPreset** | Preset for gameplay settings | Default | Default / Relaxed / Hard / Survival / Custom (`ENSHROUDED_GS_PRESET`) |

### Difficulty Presets Explanation

- **Default** - This is the standard difficulty baseline.
- **Relaxed** - Fewer enemies, more resources and loot.
- **Hard** - Increased enemy count and aggression.
- **Survival** - More punishing experience with stronger survival pressure.
- **Custom** - Allows full control over all individual gameplay settings.

---

## Gameplay Settings (Ordered by Config)

| Setting | Description | Default Value | Min | Max | Options / Notes |
|----------------------------------|----------------------------------------------------------|------------------------|----------------------|----------------------|--------------------------------------------------------------|
| **playerHealthFactor** | Scales player max health | 1 | 0.25 | 4 | `ENSHROUDED_GS_PLAYER_HEALTH_FACTOR` |
| **playerManaFactor** | Scales player max mana | 1 | 0.25 | 4 | `ENSHROUDED_GS_PLAYER_MANA_FACTOR` |
| **playerStaminaFactor** | Scales player max stamina | 1 | 0.25 | 4 | `ENSHROUDED_GS_PLAYER_STAMINA_FACTOR` |
| **playerBodyHeatFactor** | Adjusts cold resistance/body heat pool | 1 | 0.5 | 2 | Allowed values: 0.5 / 1 / 1.5 / 2 (`ENSHROUDED_GS_PLAYER_BODY_HEAT_FACTOR`) |
| **playerDivingTimeFactor** | Sets starting oxygen for swimming and diving | 1 | 0.5 | 2 | Higher values provide more underwater time (`ENSHROUDED_GS_PLAYER_DIVING_TIME_FACTOR`) |
| **enableDurability** | Weapon/tool durability enabled | true | - | - | true / false (`ENSHROUDED_GS_ENABLE_DURABILITY`) |
| **enableStarvingDebuff** | Enables hunger / starvation damage | false | - | - | true / false (`ENSHROUDED_GS_ENABLE_STARVING_DEBUFF`) |
| **foodBuffDurationFactor** | Multiplies food buff durations | 1 | 0.5 | 2 | `ENSHROUDED_GS_FOOD_BUFF_DURATION_FACTOR` |
| **fromHungerToStarving** | Hungry-state length before starvation (ns) | 600000000000 (10 min) | 300000000000 (5 min) | 1200000000000 (20 min) | Nanoseconds (`ENSHROUDED_GS_FROM_HUNGER_TO_STARVING`) |
| **shroudTimeFactor** | Time permitted within the Shroud | 1 | 0.5 | 2 | `ENSHROUDED_GS_SHROUD_TIME_FACTOR` |
| **tombstoneMode** | Items lost on death | AddBackpackMaterials | - | - | AddBackpackMaterials / Everything / NoTombstone (`ENSHROUDED_GS_TOMBSTONE_MODE`) |
| **enableGliderTurbulences** | Enables glider turbulence | true | - | - | true / false (`ENSHROUDED_GS_ENABLE_GLIDER_TURBULENCES`) |
| **weatherFrequency** | Frequency of dynamic weather events | Normal | - | - | Disabled / Rare / Normal / Often (`ENSHROUDED_GS_WEATHER_FREQUENCY`) |
| **fishingDifficulty** | Strength of fish during the mini-game | Normal | - | - | VeryEasy / Easy / Normal / Hard / VeryHard (`ENSHROUDED_GS_FISHING_DIFFICULTY`) |
| **miningDamageFactor** | Mining damage and terraforming speed | 1 | 0.5 | 2 | `ENSHROUDED_GS_MINING_DAMAGE_FACTOR` |
| **plantGrowthSpeedFactor** | Growth speed for crops | 1 | 0.25 | 2 | `ENSHROUDED_GS_PLANT_GROWTH_SPEED_FACTOR` |
| **resourceDropStackAmountFactor** | Materials per loot stack | 1 | 0.25 | 2 | `ENSHROUDED_GS_RESOURCE_DROP_STACK_AMOUNT_FACTOR` |
| **factoryProductionSpeedFactor** | Workstation production times | 1 | 0.25 | 2 | Higher values reduce crafting duration (`ENSHROUDED_GS_FACTORY_PRODUCTION_SPEED_FACTOR`) |
| **perkUpgradeRecyclingFactor** | Rune refund when salvaging upgraded weapons | 0.5 | 0 | 1 | `ENSHROUDED_GS_PERK_UPGRADE_RECYCLING_FACTOR` |
| **perkCostFactor** | Rune cost multiplier for weapon upgrades | 1 | 0.25 | 2 | `ENSHROUDED_GS_PERK_COST_FACTOR` |
| **experienceCombatFactor** | XP gained from combat | 1 | 0.25 | 2 | `ENSHROUDED_GS_EXPERIENCE_COMBAT_FACTOR` |
| **experienceMiningFactor** | XP gained from mining | 1 | 0 | 2 | `ENSHROUDED_GS_EXPERIENCE_MINING_FACTOR` |
| **experienceExplorationQuestsFactor** | XP gained from exploration and quests | 1 | 0.25 | 2 | `ENSHROUDED_GS_EXPERIENCE_EXPLORATION_QUESTS_FACTOR` |
| **randomSpawnerAmount** | Ambient enemy density | Normal | - | - | Few / Normal / Many / Extreme (`ENSHROUDED_GS_RANDOM_SPAWNER_AMOUNT`) |
| **aggroPoolAmount** | Simultaneous attackers allowed | Normal | - | - | Few / Normal / Many / Extreme (`ENSHROUDED_GS_AGGRO_POOL_AMOUNT`) |
| **enemyDamageFactor** | Non-boss enemy damage | 1 | 0.25 | 5 | `ENSHROUDED_GS_ENEMY_DAMAGE_FACTOR` |
| **enemyHealthFactor** | Non-boss enemy health | 1 | 0.25 | 4 | `ENSHROUDED_GS_ENEMY_HEALTH_FACTOR` |
| **enemyStaminaFactor** | Non-boss stamina / stagger resistance | 1 | 0.5 | 2 | Higher values make enemies harder to stagger (`ENSHROUDED_GS_ENEMY_STAMINA_FACTOR`) |
| **enemyPerceptionRangeFactor** | Non-boss perception range | 1 | 0.5 | 2 | `ENSHROUDED_GS_ENEMY_PERCEPTION_RANGE_FACTOR` |
| **bossDamageFactor** | Boss damage | 1 | 0.2 | 5 | `ENSHROUDED_GS_BOSS_DAMAGE_FACTOR` |
| **bossHealthFactor** | Boss health | 1 | 0.2 | 5 | `ENSHROUDED_GS_BOSS_HEALTH_FACTOR` |
| **threatBonus** | Frequency of enemy attacks | 1 | 0.25 | 4 | `ENSHROUDED_GS_THREAT_BONUS` |
| **pacifyAllEnemies** | Enemies attack only when provoked (excl. bosses) | false | - | - | true / false (`ENSHROUDED_GS_PACIFY_ALL_ENEMIES`) |
| **tamingStartleRepercussion** | Progress lost when startling wildlife during taming | LoseSomeProgress | - | - | KeepProgress / LoseSomeProgress / LoseAllProgress (`ENSHROUDED_GS_TAMING_STARTLE_REPERCUSSION`) |
| **dayTimeDuration** | Daytime length (ns) | 1800000000000 (30 min) | 120000000000 (2 min) | 3600000000000 (60 min) | Smaller values shorten daytime (`ENSHROUDED_GS_DAY_TIME_DURATION`) |
| **nightTimeDuration** | Nighttime length (ns) | 720000000000 (12 min) | 120000000000 (2 min) | 3600000000000 (60 min) | Smaller values shorten nighttime (`ENSHROUDED_GS_NIGHT_TIME_DURATION`) |
| **curseModifier** | Shroud curse chance | Normal | - | - | Easy / Normal / Hard (`ENSHROUDED_GS_CURSE_MODIFIER`) |

*Time-based values (for example `fromHungerToStarving`, `dayTimeDuration`, `nightTimeDuration`) are stored in nanoseconds. Divide by `60,000,000,000` to convert to minutes.*

---

## User Groups & Permissions

### User Group Fields

| Field | Description | Type | Example Value | Options / Notes |
|----------------------|-----------------------------------------------------------------------|---------|--------------------|--------------------------------------|
| **name** | Name of the user group | String | "Admin" | Arbitrary group name |
| **password** | Password required to join the group | String / null | null | Empty/missing can be auto-generated |
| **canKickBan** | Permission to kick/ban players | Boolean | true | true / false |
| **canAccessInventories** | Permission to access other players' inventories | Boolean | true | true / false |
| **canEditWorld** | Allow terraforming / interactions outside bases | Boolean | true | true / false |
| **canEditBase** | Permission to edit any base | Boolean | true | true / false |
| **canExtendBase** | Permission to extend base territory | Boolean | true | true / false |
| **reservedSlots** | Reserved player slots for that group | Int | 0 | Integer >= 0 |

---

### Defined User Groups

The default template ships with four predefined user groups: **Admin**, **Friend**, **Guest**, and **Visitor**.

| Group Name | Password | Can Kick/Ban | Access Inventories | Can Edit World | Edit Base | Extend Base | Reserved Slots |
|------------|------------------------------|--------------|--------------------|----------------|-----------|-------------|----------------|
| **Admin**  | `null` (auto-generated later) | true | true | true | true | true | 0 |
| **Friend** | `null` (auto-generated later) | false | true | true | true | false | 0 |
| **Guest**  | `null` (auto-generated later) | false | false | true | false | false | 0 |
| **Visitor**| `null` (auto-generated later) | false | false | false | false | false | 0 |

### Role Descriptions

- **Admin**: Full administrative privileges, including kick/ban powers, inventory access, world terraforming, and unrestricted base edits or extensions.
- **Friend**: Trusted players who may terraform the world and build inside the base but cannot kick/ban other players or extend the base claim.
- **Guest**: Adventurers who can explore and interact with the world while keeping inventories and bases protected from accidental edits.
- **Visitor**: A safe default role that cannot terraform outside the base, edit builds, or access other inventories.

### Ban List

The `bans` array stores permanently banned player IDs. Leave it empty for open servers.

For compatibility, some workflows also handle `bannedAccounts` (legacy/newer key handling). The menu tooling keeps both ban arrays in sync when needed.

For official gameplay documentation, see:
[Enshrouded Server Gameplay Settings](https://enshrouded.zendesk.com/hc/en-us/articles/20453241249821-Server-Gameplay-Settings)
