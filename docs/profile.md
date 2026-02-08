# Profiles

Diese Datei beschreibt beide Profilarten im aktuellen Layout.

## Dateistruktur

- Manager-Profile: `server_manager/profiles/manager/<name>_server_manager.json`
- Enshrouded-Profile: `server_manager/profiles/enshrouded/<name>_enshrouded_server.json`

Im Container:
- Manager-Templates: `/usr/local/etc/enshrouded/profiles/manager/`
- Enshrouded-Templates: `/usr/local/etc/enshrouded/profiles/enshrouded/`

Laufzeitkopien:
- Manager-Konfig: `/server_manager/server_manager.json`
- Manager-Profile-Store: `/profile/<name>/<name>_server_manager.json`
- Enshrouded-Konfig: `/opt/enshrouded/server/enshrouded_server.json`

## Auswahl

- `MANAGER_PROFILE=<name>`
- `EN_PROFILE=<name>`

Wenn ein Profilname fehlt/ungültig ist, wird auf `default` zurückgefallen.

## Reset-Commands

- `profile-reset`:
  - setzt `/server_manager/server_manager.json` aus dem gewählten `MANAGER_PROFILE` zurück
  - stoppt danach `supervisord` für sauberen Neustart
- `enshrouded-profile-reset`:
  - setzt `/opt/enshrouded/server/enshrouded_server.json` aus `EN_PROFILE` zurück
  - stoppt danach `supervisord` für sauberen Neustart
