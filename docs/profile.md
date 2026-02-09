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

## Selection

- `MANAGER_PROFILE=<name>`
- `EN_PROFILE=<name>`

If a profile name is missing/invalid, it falls back to `default`.

## Reset Commands

- `profile-reset`:
  - resets `/home/enshrouded/server/server_manager/server_manager.json` from the selected `MANAGER_PROFILE`
  - stops `supervisord` afterwards for a clean restart
- `enshrouded-profile-reset`:
  - resets `/home/enshrouded/server/enshrouded_server.json` from `EN_PROFILE`
  - stops `supervisord` afterwards for a clean restart
