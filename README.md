# Enshrouded Dedicated Server Docker

## Full Settings + Example Config

- Environment variables: [`docs/environment.md`](docs/environment.md)
- Profile system (Manager + Enshrouded): [`docs/profile.md`](docs/profile.md)
- Commands: [`docs/server_manager_commands.md`](docs/server_manager_commands.md)
- Logging behavior: [`docs/log.md`](docs/log.md)
- Current init changelog: [`docs/changelog/v3.0.0.md`](docs/changelog/v3.0.0.md)

---

## Quickstart

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e EN_PROFILE="default" \
  -e MANAGER_PROFILE="default" \
  -e ENSHROUDED_NAME="Enshrouded Server" \
  -e ENSHROUDED_ROLE_0_PASSWORD="ChangeMeAdminPassword" \
  -e LOG_COLOR="true" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  -v /home/enshrouded/server_1/server_manager:/server_manager \
  -v /home/enshrouded/server_1/profile:/profile \
  bonsaibauer/enshrouded_server_docker:dev_latest
```

Hinweis:
- Das aktuelle Server-Installziel im Container ist `/home/enshrouded/server`.
- Für persistente Manager-/Profil-Daten sind die Volumes `/server_manager` und `/profile` relevant.
