# Profiles

This file describes both profile types in the current layout.

## File Structure

- Manager-Profile: `server_manager/profiles/manager/<name>_server_manager.json`
- Enshrouded-Profile: `server_manager/profiles/enshrouded/<name>_enshrouded_server.json`

In the container:
- Manager-Templates: `/usr/local/etc/enshrouded/profiles/manager/`
- Enshrouded-Templates: `/usr/local/etc/enshrouded/profiles/enshrouded/`

Runtime copies:
- Manager-Konfig: `/home/enshrouded/server/server_manager/server_manager.json`
- Manager-Profile-Store: `/home/enshrouded/server/profile/<name>/<name>_server_manager.json`
- Enshrouded-Konfig: `/home/enshrouded/server/enshrouded_server.json`

## Creating New Profiles

Profiles are template JSON files shipped inside the image. To add your own, create a new template file in this repo and rebuild the image (or mount your own templates into the container).

Naming rules:

- `<name>` must match `^[A-Za-z0-9._-]+$`
- File names must follow the exact suffix pattern:
  - `*_enshrouded_server.json`
  - `*_server_manager.json`

### Enshrouded Profile

1. Copy `server_manager/profiles/enshrouded/default_enshrouded_server.json` to `server_manager/profiles/enshrouded/<name>_enshrouded_server.json`
2. Edit the JSON (must stay valid JSON)
3. Rebuild the Docker image
4. Select it with `EN_PROFILE=<name>` or via `ctl menu`

### Server Manager Profile

1. Copy `server_manager/profiles/manager/default_server_manager.json` to `server_manager/profiles/manager/<name>_server_manager.json`
2. Edit the JSON (see `docs/environment.md` for variable meanings)
3. Rebuild the Docker image
4. Select it with `MANAGER_PROFILE=<name>` or via `ctl menu`

When selected, the Server Manager template is copied into the persistent profile store at:

- `/home/enshrouded/server/profile/<name>/<name>_server_manager.json`

## Selection

- `MANAGER_PROFILE=<name>`
- `EN_PROFILE=<name>`

If a profile name is missing/invalid, it falls back to `default`.

### Persisted Selection (via `ctl menu`)

If the file below exists, it is used as the preferred profile selector (allows switching profiles without changing container env vars):

- `/home/enshrouded/server/server_manager/profile_selection.json`

Keys:
- `manager`: profile name for `server_manager.json`
- `enshrouded`: profile name for `enshrouded_server.json`

## Reset Commands

- `profile-reset`:
  - resets `/home/enshrouded/server/server_manager/server_manager.json` from the selected `MANAGER_PROFILE`
  - creates a timestamped backup in `BACKUP_DIR/profiles` before replacing the config
  - stops `supervisord` afterwards for a clean restart
- `enshrouded-profile-reset`:
  - resets `/home/enshrouded/server/enshrouded_server.json` from `EN_PROFILE`
  - creates a timestamped backup in `BACKUP_DIR/profiles` before replacing the config
  - stops `supervisord` afterwards for a clean restart
