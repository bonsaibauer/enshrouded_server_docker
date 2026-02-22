# Enshrouded Dedicated Server Docker

> [!TIP]
> 🔥 **HELLO FLAMEBORN** 🔥  
> Spin up your world in minutes. Keep the fun, skip the admin pain.

This repository is built for players who want a powerful Enshrouded server without wrestling Docker all day. Start the container, open the menu, and the manager takes over the annoying parts: updates, restarts, backups, profile handling, validation, and process control.

## Why This Is So Easy To Use 😎

The idea is simple: one control center, one clean workflow, less stress. With `server menu`, you handle your full server lifecycle from one place: start, stop, restart, update, profile switch, backup, restore, and maintenance tasks. Settings are validated before they can break anything, so beginners can run this stack safely.

Profiles work like game presets. Keep one profile for relaxed co-op, another for harder sessions, another for testing, then switch in seconds. No manual config surgery, no guessing.

Backups are built in as real safety gear. Create manual backups anytime, let scheduled backups run automatically, inspect backup contents, and restore exactly what you need. Full restore, partial restore, and safety-backup-before-restore are all there.

## Power Features Without The Headache ⚔️

Under the hood, Supervisor orchestrates the core jobs (`server`, `updater`, `backup`, `restart`, `bootstrap`, `cron`, and more), so behavior stays stable and predictable. The runtime ships with a current **GE-Proton** base (default: **GE-Proton 10-28**) for strong compatibility and stable long-running performance.

When you want more control, it is already ready: `restart force`, `restart player-check`, `scheduled-restart`, `update check`, `update force`, `backup list`, `backup inspect`, `backup restore`, `cron sync`, `status`, `password-view`, and `env-validation`. Hooks and guard checks add another safety layer by blocking risky actions when services are not ready.

In short: easy for beginners on the surface, serious server power underneath.

## Quickstart - Hello Flameborn 🔥

Step 1: launch your server container.

```bash
docker run \
  --name enshroudedserver \
  --restart=unless-stopped \
  --stop-timeout 90 \
  -p 15637:${ENSHROUDED_QUERY_PORT:=15637}/udp \
  -e PUID="$(id -u enshrouded)" \
  -e PGID="$(id -g enshrouded)" \
  -e ENSHROUDED_QUERY_PORT \
  -v /home/enshrouded/server_1:/home/enshrouded/server \
  bonsaibauer/enshrouded_server_docker:dev_latest
```

Step 2: open your in-container control center.

```bash
docker exec -it enshroudedserver server menu
```

Step 3: pick a profile, start your server, and create your first backup from the menu.

For safe full container shutdown, use:

```bash
docker stop -t 90 enshroudedserver
```

If your container name is different, replace `enshroudedserver` (check with `docker ps`).

## Full Settings + Example Config

- Environment variables: [`docs/environment.md`](docs/environment.md)
- Profile system (Manager + Enshrouded): [`docs/profile.md`](docs/profile.md)
- Commands: [`docs/server_manager_commands.md`](docs/server_manager_commands.md)
- Interactive menu: [`docs/menu.md`](docs/menu.md)
- Logging behavior: [`docs/log.md`](docs/log.md)
- Current init changelog: [`docs/changelog/v3.0.0.md`](docs/changelog/v3.0.0.md)
- Dev branch logs (unofficial): [`docs/changelog/dev-logs.md`](docs/changelog/dev-logs.md)

---

> [!WARNING]
> **Externe Verlinkungen**  
> Für Inhalte externer Websites, auf die direkt oder indirekt verwiesen wird, wird keine Haftung übernommen. Zum Zeitpunkt der Verlinkung waren keine Rechtsverstöße erkennbar.

> [!NOTE]
> Diese Informationen dienen ausschließlich Dokumentationszwecken.  
> Es wird keine Gewähr für Vollständigkeit oder Aktualität übernommen.
