# Enshrouded Dedicated Server Docker

## Full Settings + Example Config

- Environment variables: [`docs/environment.md`](docs/environment.md)
- Profile system (Manager + Enshrouded): [`docs/profile.md`](docs/profile.md)
- Commands: [`docs/server_manager_commands.md`](docs/server_manager_commands.md)
- Interactive menu: [`docs/menu.md`](docs/menu.md)
- Logging behavior: [`docs/log.md`](docs/log.md)
- Current init changelog: [`docs/changelog/v3.0.0.md`](docs/changelog/v3.0.0.md)
- Dev branch logs (unofficial): [`docs/changelog/dev-logs.md`](docs/changelog/dev-logs.md)

---

## Quickstart

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  -p 15637:15637/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:dev_latest
```

### Interactive Menu

```bash
docker exec -it enshroudedserver server menu
```

If your container has a different name, replace `enshroudedserver` (see `docker ps`).
