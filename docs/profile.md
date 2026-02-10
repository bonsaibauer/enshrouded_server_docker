# Profiles

This file describes both profile types in the current layout.

## File Structure

- Manager-Profile: `server_manager/profiles/manager/<name>_server_manager.json`
- Enshrouded-Profile: `server_manager/profiles/enshrouded/<name>_enshrouded_server.json`

In the container:
- Manager-Templates (shipped): `/usr/local/etc/enshrouded/profiles/manager/`
- Enshrouded-Templates (shipped): `/usr/local/etc/enshrouded/profiles/enshrouded/`

Runtime copies:
- Manager config: `/home/enshrouded/server/server_manager/server_manager.json`
- Manager-Profile-Store: `/home/enshrouded/server/profile/<name>/<name>_server_manager.json`
- Enshrouded config: `/home/enshrouded/server/enshrouded_server.json`

Persistent profile catalogs (volume):
- Manager-Profile-Catalog (default `MANAGER_PROFILE_TEMPLATE_DIR`): `/home/enshrouded/server/profiles/manager/`
  - Seeded from the shipped templates on container start (copy only missing files)
- Enshrouded-Profile-Catalog (default `EN_PROFILE_DIR`): `/home/enshrouded/server/profiles/enshrouded/`
  - Seeded from the shipped templates on container start (copy only missing files)

## Creating New Profiles

Profiles are template JSON files. Shipped templates live inside the image and are (by default) copied into the persistent volume catalog on container start.

To add your own profiles without rebuilding the image, drop new `*_enshrouded_server.json` template files into:

- `/home/enshrouded/server/profiles/enshrouded/`

Naming rules:

- `<name>` must match `^[A-Za-z0-9._-]+$`
- File names must follow the exact suffix pattern:
  - `*_enshrouded_server.json`
  - `*_server_manager.json`

### Enshrouded Profile

1. Copy `server_manager/profiles/enshrouded/default_enshrouded_server.json` to `server_manager/profiles/enshrouded/<name>_enshrouded_server.json`
2. Edit the JSON (must stay valid JSON)
3. Put the file into the volume catalog: `/home/enshrouded/server/profiles/enshrouded/` (or rebuild the image to ship it)
4. Select it with `EN_PROFILE=<name>` or via `ctl menu`

### Server Manager Profile

1. Copy `server_manager/profiles/manager/default_server_manager.json` to `server_manager/profiles/manager/<name>_server_manager.json`
2. Edit the JSON (see `docs/environment.md` for variable meanings)
3. Put the file into the volume catalog: `/home/enshrouded/server/profiles/manager/` (or rebuild the image to ship it)
4. Select it with `MANAGER_PROFILE=<name>` or via `ctl menu`

When selected, the Server Manager template is copied into the persistent profile store at:

- `/home/enshrouded/server/profile/<name>/<name>_server_manager.json`

## Selection

- `MANAGER_PROFILE=<name>`
- `EN_PROFILE=<name>`

If a profile name is missing/invalid, it falls back to `default`.

### Persisted Selection (via `ctl menu`)

Profile selection is stored directly in the Server Manager config file:

- `/home/enshrouded/server/server_manager/server_manager.json`

Keys:
- `actualProfilManager`: profile name for `server_manager.json`
- `actualProfilEnshrouded`: profile name for `enshrouded_server.json`

The initial ENV selectors are captured once for transparency:
- `MANAGER_PROFILE`
- `EN_PROFILE`

## Reset Commands

- `server-manager-profil-reset`:
  - resets `/home/enshrouded/server/server_manager/server_manager.json` from the selected manager profile (`actualProfilManager`)
  - creates a timestamped backup in `BACKUP_DIR/profiles` before replacing the config
  - stops `supervisord` afterwards for a clean restart
- `enshrouded-profile-reset`:
  - resets `/home/enshrouded/server/enshrouded_server.json` from the selected Enshrouded profile (`actualProfilEnshrouded`)
  - creates a timestamped backup in `BACKUP_DIR/profiles` before replacing the config
  - stops `supervisord` afterwards for a clean restart
