# Profiles

This file compares profile templates by **core features only** so new profiles can be added side by side.

---

## Profiles for `enshrouded_server.json`

### Core comparison table

| Status | Profile name | `slotCount` | Voice chat | Text chat | `gameSettingsPreset` | Detailed `gameSettings.*` active? | Detailed settings source | User-group model | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `[x]` | `default` | `16` | ❌ | ❌ | `"Default"` | ❌ (only active when preset is `"Custom"`) | [`default_enshrouded_server.json`](../server_manager/profiles/enshrouded/default_enshrouded_server.json) | 4 groups: Admin/Friend/Guest/Visitor | Currently shipped and active in quickstart examples |
| `[ ]` | `<new_profile>` | `<set>` | ✅/❌ | ✅/❌ | `<set>` | ✅ when preset is `"Custom"`, otherwise ❌ | `server_manager/profiles/enshrouded/<new_profile>_enshrouded_server.json` | same schema (4 groups) | Add future profiles here for side-by-side comparison |

> [!NOTE]
> Individual `gameSettings.*` values only take effect when `gameSettingsPreset` is set to `"Custom"`.
> For `Custom`, detailed values are not expanded here. Check the respective profile JSON file directly.

### User-group schema (stable across profiles)

Every profile uses the same role schema with four groups:

| Group Name | Can Kick/Ban | Access Inventories | Can Edit World | Edit Base | Extend Base | Reserved Slots |
|------------|--------------|--------------------|----------------|-----------|-------------|----------------|
| **Admin**  | ✅          | ✅                 | ✅             | ✅        | ✅        | 0              |
| **Friend** | ❌          | ✅                 | ✅             | ✅        | ❌        | 0              |
| **Guest**  | ❌          | ❌                 | ✅             | ❌        | ❌        | 0              |
| **Visitor**| ❌          | ❌                 | ❌             | ❌        | ❌        | 0              |

---

## Profiles for `server_manager.json`

### Feature schema (stable across profiles)

The same core feature categories are compared for every Server Manager profile:

| Category | Purpose | Key set |
| --- | --- | --- |
| Player checks | Control whether update/restart waits for zero players | `updateCheckPlayers`, `restartCheckPlayers`, `restartDowntimeSeconds` |
| Backups | Control backup behavior and retention | `backupMaxCount`, `backupScheduledIncludeEnshroudedConfig`, `backupScheduledIncludeServerManagerConfig` |
| Scheduled cron | Control scheduled update/backup/restart jobs | `updateCron`, `backupCron`, `restartCron` |

### Core comparison table

| Status | Profile name | Update check players | Restart check players | Manual backup | Scheduled backup | `backupMaxCount` | `backupCron` | `updateCron` | `restartCron` | Source | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `[x]` | `default` | ❌ (`updateCheckPlayers=false`) | ❌ (`restartCheckPlayers=false`, downtime=`5s`) | ✅ | ❌ | `0` | ❌ | ❌ | ❌ | [`default_server_manager.json`](../server_manager/profiles/manager/default_server_manager.json) | Currently shipped and active in quickstart examples |
| `[ ]` | `<new_profile>` | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | `<number>` | ❌ / ✅ (`0 4 * * *` = 04:00 AM) | ❌ / ✅ (`0 5 * * *` = 05:00 AM) | ❌ / ✅ (`10 5 * * *` = 05:10 AM) | `server_manager/profiles/manager/<new_profile>_server_manager.json` | Add future profiles here for side-by-side comparison |

> [!NOTE]
> If cron is not set, no automatic backup/update/restart is executed.
> Manual backups are still available (for example via `docker exec <container> backup` or the menu).
> `backupMaxCount` is mainly relevant for automatic/scheduled backup cleanup when `backupCron` is configured.

---

## Selection

- `EN_PROFILE=<name>`
- `MANAGER_PROFILE=<name>`

If a selected profile is missing or invalid, fallback is `default`.