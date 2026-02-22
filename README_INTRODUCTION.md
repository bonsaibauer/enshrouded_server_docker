![Enshrouded Server Docker Banner](images/banner.png)

# Enshrouded Dedicated Server Docker - Introduction

> [!TIP]
> 🔥 **HELLO FLAMEBORN** 🔥  
> Start fast, stay stable, and spend your time playing instead of fixing server drama.

This introduction is for players who want a strong Enshrouded server setup without becoming full-time Docker admins.  
You launch the container, open the menu, and the server manager handles the hard parts for you: updates, restarts, backups, profile switching, validation, and safe process control.

## Why People Use This Setup

You get one clean workflow instead of scattered scripts and random manual fixes. The important part is that this stack manages two different config areas, and both are exposed in one flow:

- **Enshrouded Server settings**: gameplay/world settings like slots, ports, rules, tags, and user groups (`enshrouded_server.json`).
- **Server Manager settings**: automation/operations like backup behavior, restart schedules, update checks, cron sync, hooks, and runtime handling (`server_manager.json`).

Profiles are concrete presets for those configs.  
An **Enshrouded profile** is a preconfigured gameplay/server setup.  
A **Manager profile** is a preconfigured operations setup (for example backup strategy and restart/update behavior).

Backups are also concrete: you can back up savegame + both config files, inspect what is inside each ZIP, and restore either everything or only selected parts. This makes testing safer because rollback is always available.

> [!TIP]
> 🎛️ Open the control center with: `docker exec -it enshroudedserver server menu`

## Feature Breakdown (Simple + Powerful) ⚡

### 🎛️ Interactive Menu (`server menu`)

The menu is your all-in-one control center for both config layers. Instead of memorizing complex commands, you run one guided flow for start, stop, restart, update, profile apply/reset, backup, and restore.  
You can edit Enshrouded gameplay settings and Server Manager automation settings in one place, so beginners can operate a real server without command-line overload.

### 🧠 Supervisor = Stable Process Brain

Supervisor is the process manager that keeps everything organized under the hood.  
It orchestrates jobs like `server`, `updater`, `backup`, `restart`, `bootstrap`, and `cron`, so actions run in a predictable and controlled way.  
Result: less chaos, better uptime, and cleaner recovery behavior when something fails.

### 💾 Backup + Restore Safety

Backup is not an extra script here, it is a core feature.  
You can create manual backups, run scheduled backups, list them, inspect them, and restore only the parts you need (or everything).  
Restore supports component-level targeting, so you can choose savegame only, Enshrouded config only, Manager config only, or full recovery.  
If you want maximum safety, use a safety backup before restore so rollback is always possible.

### 🚀 Best-Performance Runtime Setup (Why GE-Proton)

Enshrouded Dedicated Server runs as a Windows target on Linux, so Proton compatibility quality matters.  
This image uses a current **GE-Proton** base (default: **GE-Proton 10-28**) because it is known for practical compatibility fixes and stable runtime behavior in real hosting environments.  
Combined with controlled restart/update flows, player-aware checks, and safe stop grace, this gives you a strong balance of performance, compatibility, and long-running stability.

## Command + Feature Roadmap

> [!NOTE]
> Status legend: `✅ Live` = available now, `🟡 In Progress` = currently being built, `⚪ Not Yet` = planned idea.

| Command | Description | Roadmap Status |
|---|---|---|
| `menu` | Opens the interactive control center for daily server management. | ✅ Live |
| `status` | Shows supervisor state for jobs like `server`, `updater`, `backup`, and `cron`. | ✅ Live |
| `start` / `stop` | Starts or stops the game server safely. | ✅ Live |
| `restart` | Controlled restart flow with downtime handling. | ✅ Live |
| `scheduled-restart` | Runs the same restart logic used by cron schedules. | ✅ Live |
| `restart player-check` | Restarts only when no players are online (player-aware safety). | ✅ Live |
| `update` | Normal update flow with SteamCMD integration. | ✅ Live |
| `update check` | Checks if an update is available without installing it. | ✅ Live |
| `update force` | Forces a clean update path. | ✅ Live |
| `backup` | Creates a manual backup archive. | ✅ Live |
| `backup list` | Lists available backup archives. | ✅ Live |
| `backup inspect <zip>` | Shows what is inside a backup archive before restore. | ✅ Live |
| `backup restore <zip> [target]` | Restores full backup or only selected components. | ✅ Live |
| `backup-config` | Creates config-only backup without savegame data. | ✅ Live |
| `profile <manager\|enshrouded> <apply\|reset>` | Applies or resets profile-based server configurations. | ✅ Live |
| `password-view` | Displays user-group password/rights information from config. | ✅ Live |
| `cron sync` | Rebuilds cron entries from current runtime config. | ✅ Live |
| `env-validation verify` | Validates env values and setup consistency. | ✅ Live |
| `hook-run` | Runs custom hook commands for automation workflows. | ✅ Live |
| `profile packs` | Ready-made profile packs for different playstyles. | 🟡 In Progress |
| `dashboard` | Optional browser-based admin panel experience. | ⚪ Not Yet |
| `notify` | Built-in notification channel integration (e.g., webhook/Discord style). | ⚪ Not Yet |

## Quick Entry

Run container:

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

Open menu:

```bash
docker exec -it enshroudedserver server menu
```

Safe full shutdown:

```bash
docker stop -t 90 enshroudedserver
```
