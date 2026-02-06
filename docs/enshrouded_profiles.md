# Enshrouded Server Profiles

Profiles define the initial defaults that are written to `enshrouded_server.json` when it is created for the first time. After creation, profiles are not re-applied; runtime precedence is ENV > `enshrouded_server.json`.
No profile metadata is stored in `enshrouded_server.json`.

If you want to switch profiles on an existing setup, you must delete or rename `enshrouded_server.json` and restart the container.

Profile selection:
- `EN_PROFILE` (ENV) if set and valid
- Otherwise `default`

Profile files:
- `default`: `../server_manager/profiles_enshrouded/default/enshrouded_server.json`

Important:
- Profile files do not contain passwords.
- If a `userGroups[*].password` is empty or null, a password is generated (unless an `ENSHROUDED_ROLE_<index>_PASSWORD` override is set).
- The profile's `userGroups` list is used as-is on first creation (no automatic additions).

## Default Profile

JSON: `../server_manager/profiles_enshrouded/default/enshrouded_server.json`

General settings:
| Setting | Value | Notes |
|---|---|---|
| `name` | `Enshrouded Server` | Server name |
| `saveDirectory` | `./savegame` | Relative to `INSTALL_PATH` |
| `logDirectory` | `./logs` | Relative to `INSTALL_PATH` |
| `ip` | `0.0.0.0` | Bind all interfaces |
| `queryPort` | `15637` | UDP query port |
| `slotCount` | `16` | Max players |
| `tags` | `[]` | Empty tags list |
| `voiceChatMode` | `Proximity` | Voice chat mode |
| `enableVoiceChat` | `false` | Voice chat disabled |
| `enableTextChat` | `false` | Text chat disabled |
| `gameSettingsPreset` | `Default` | Gameplay preset |

Game settings:
| Setting | Value | Notes |
|---|---|---|
| `playerHealthFactor` | `1` | Default |
| `playerManaFactor` | `1` | Default |
| `playerStaminaFactor` | `1` | Default |
| `playerBodyHeatFactor` | `1` | Default |
| `playerDivingTimeFactor` | `1` | Default |
| `enableDurability` | `true` | Enabled |
| `enableStarvingDebuff` | `false` | Disabled |
| `foodBuffDurationFactor` | `1` | Default |
| `fromHungerToStarving` | `600000000000` | Nanoseconds |
| `shroudTimeFactor` | `1` | Default |
| `tombstoneMode` | `AddBackpackMaterials` | Default |
| `enableGliderTurbulences` | `true` | Enabled |
| `weatherFrequency` | `Normal` | Default |
| `fishingDifficulty` | `Normal` | Default |
| `miningDamageFactor` | `1` | Default |
| `plantGrowthSpeedFactor` | `1` | Default |
| `resourceDropStackAmountFactor` | `1` | Default |
| `factoryProductionSpeedFactor` | `1` | Default |
| `perkUpgradeRecyclingFactor` | `0.5` | Default |
| `perkCostFactor` | `1` | Default |
| `experienceCombatFactor` | `1` | Default |
| `experienceMiningFactor` | `1` | Default |
| `experienceExplorationQuestsFactor` | `1` | Default |
| `randomSpawnerAmount` | `Normal` | Default |
| `aggroPoolAmount` | `Normal` | Default |
| `enemyDamageFactor` | `1` | Default |
| `enemyHealthFactor` | `1` | Default |
| `enemyStaminaFactor` | `1` | Default |
| `enemyPerceptionRangeFactor` | `1` | Default |
| `bossDamageFactor` | `1` | Default |
| `bossHealthFactor` | `1` | Default |
| `threatBonus` | `1` | Default |
| `pacifyAllEnemies` | `false` | Disabled |
| `tamingStartleRepercussion` | `LoseSomeProgress` | Default |
| `dayTimeDuration` | `1800000000000` | Nanoseconds |
| `nightTimeDuration` | `720000000000` | Nanoseconds |
| `curseModifier` | `Normal` | Default |

User groups:
| Name | Password | Can Kick/Ban | Access Inventories | Can Edit World | Edit Base | Extend Base | Reserved Slots |
|---|---|---|---|---|---|---|---|
| `Admin` | `null` | `true` | `true` | `true` | `true` | `true` | `0` |
| `Friend` | `null` | `false` | `true` | `true` | `true` | `false` | `0` |
| `Guest` | `null` | `false` | `false` | `true` | `false` | `false` | `0` |
| `Visitor` | `null` | `false` | `false` | `false` | `false` | `false` | `0` |

Other:
| Setting | Value | Notes |
|---|---|---|
| `bans` | `[]` | Empty by default |

## Additional Profiles

No additional Enshrouded profiles are shipped. To add one, create:
- `server_manager/profiles_enshrouded/<profile>/enshrouded_server.json`

Document additional profiles here as differences from `default`.
