# Changelog (New)

All relevant `server_manager` changes made in this chat session.

## [Unreleased]

### Added
- Automatic password generation for `userGroups` in `enshrouded_server.json`:
  - If `password` in JSON is empty/null and **no** `ENSHROUDED_ROLE_<index>_PASSWORD` ENV variable is set, a random password is generated.
  - Passwords are **not** printed to console output.
- Simple in-container command mapping for `docker exec`:
  - Added dispatcher script: `/usr/local/etc/enshrouded/ctl`
  - Added command aliases in `/usr/local/bin` so direct calls work:
    - `status`
    - `start`
    - `stop`
    - `restart`
    - `update`
    - `backup`
    - `scheduled-restart`
    - `force-update`
    - `reset-roles`
    - `bootstrap`
    - `cron-start`
    - `cron-stop`
    - `cron-restart`

#### Docker Exec Command Map
- `docker exec <target> status` -> `supervisorctl status`
- `docker exec <target> start` -> `supervisorctl start enshrouded-server`
- `docker exec <target> stop` -> `supervisorctl stop enshrouded-server`
- `docker exec <target> restart` -> `supervisorctl restart enshrouded-server`
- `docker exec <target> update` -> `supervisorctl start enshrouded-updater`
- `docker exec <target> backup` -> `supervisorctl start enshrouded-backup`
- `docker exec <target> scheduled-restart` -> `supervisorctl start enshrouded-restart`
- `docker exec <target> force-update` -> `supervisorctl start enshrouded-force-update`
- `docker exec <target> reset-roles` -> `supervisorctl start enshrouded-reset-roles`
- `docker exec <target> bootstrap` -> `supervisorctl start enshrouded-bootstrap`
- `docker exec <target> cron-start` -> `supervisorctl start crond`
- `docker exec <target> cron-stop` -> `supervisorctl stop crond`
- `docker exec <target> cron-restart` -> `supervisorctl restart crond`

#### Logic Notes
- `reset-roles` triggers `enshrouded-reset-roles`, which removes `userGroups` and then stops `supervisord` (container restart behavior).

#### Classic Supervisorctl Commands (still valid)
- `docker compose exec <service> supervisorctl status`
- `docker compose exec <service> supervisorctl start enshrouded-server`
- `docker compose exec <service> supervisorctl stop enshrouded-server`
- `docker compose exec <service> supervisorctl restart enshrouded-server`
- `docker compose exec <service> supervisorctl start enshrouded-updater`
- `docker compose exec <service> supervisorctl start enshrouded-backup`
- `docker compose exec <service> supervisorctl start enshrouded-restart`
- `docker compose exec <service> supervisorctl start enshrouded-force-update`
- `docker compose exec <service> supervisorctl start enshrouded-reset-roles`
- `docker compose exec <service> supervisorctl start enshrouded-bootstrap`
- `docker compose exec <service> supervisorctl start crond`
- `docker compose exec <service> supervisorctl stop crond`
- `docker compose exec <service> supervisorctl restart crond`

### Changed
- Profile/config file names were switched to a clearer naming scheme:
  - Server manager profile files: `<profile>_server_manager.json`
  - Enshrouded profile files: `<profile>_enshrouded_server.json`
  - Default files:
    - `profiles/default_server_manager.json`
    - `profiles_enshrouded/default_enshrouded_server.json`
- Profile path logic in `default/profile` was updated accordingly:
  - Template loading and profile resolving now use the new filename scheme.
- Script sourcing was updated to use files without extension:
  - `default/profile.sh` -> `default/profile`
  - `default/env.sh` -> `default/env`
  - All affected bootstrap/runtime scripts were updated.
- Enshrouded config initialization now uses profile files only during bootstrap (no embedded JSON template in scripts).
- Script-level hardcoded defaults for core runtime values were removed; defaults now live in JSON profiles.
- `profiles/default_server_manager.json` was aligned with previous fallback defaults (for example `puid/pgid`, `steamAppId`, `savefileName`, `backupMaxCount`, cron defaults).

### Removed
- Hard required-variable checks (`required_*`) for manager and enshrouded variables in `init_runtime_env`.
- Legacy `.sh` references for `profile`/`env`.
- Legacy default filenames `default.json` (manager/enshrouded) in the new setup.

### Notes
- ENV remains an optional override for profile values.
- Minimal, profile-centered logic: no duplicate default definitions across multiple scripts.
