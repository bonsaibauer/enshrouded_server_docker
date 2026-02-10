# Dev Branch Logs (unofficial)

This file is a **high-level** summary of what changed across the `dev*` branches.

Status note (important):
- **Functional:** `dev_1.2.1`, `dev_1.2.2`, `dev_3.1.0`
- **Non-functional:** all other `dev*` branches

The status information above is documented exactly as stated in the current request.

## Branch List / Counts

Snapshot (local + `origin`) taken on `2026-02-10`:
- `28` branch refs contain `dev` (local: `12`, remote `origin`: `16`)
- `16` unique branch names (without the `origin/` prefix)
- Alias names (same commit):
  - `dev_1.2.1` == `dev_v1.2.1`
  - `dev_1.2.2` == `dev_v1.2.2`
  - `dev_1.2.3` == `dev_v1.2.3`
  - `dev_2.0.0` == `dev_v2.0.0`

Local `dev*` branches:
- `dev_2.1.0`
- `dev_2.1.1`
- `dev_2.1.2`
- `dev_2.1.3`
- `dev_2.2.0`
- `dev_3.0.0`
- `dev_3.0.1`
- `dev_3.1.0`
- `dev_v1.2.1`
- `dev_v1.2.2`
- `dev_v1.2.3`
- `dev_v2.0.0`

Remote `origin` `dev*` branches:
- `origin/dev_1.2.1`
- `origin/dev_1.2.2`
- `origin/dev_1.2.3`
- `origin/dev_2.0.0`
- `origin/dev_2.1.0`
- `origin/dev_2.1.1`
- `origin/dev_2.1.2`
- `origin/dev_2.1.3`
- `origin/dev_2.2.0`
- `origin/dev_3.0.0`
- `origin/dev_3.0.1`
- `origin/dev_3.1.0`
- `origin/dev_v1.2.1`
- `origin/dev_v1.2.2`
- `origin/dev_v1.2.3`
- `origin/dev_v2.0.0`

## Versions / Differences (high-level)

Note: Many commits are only labeled `dev_*`, so the summary below is primarily based on changed files and structural changes per branch.

### dev_1.2.1 (functional)

Refs: `origin/dev_1.2.1`, `origin/dev_v1.2.1`, `dev_v1.2.1`

Differences (vs `v1.2`):
- CI: new/updated GitHub workflows (incl. `dev.yml`, `release.yml`)
- updated `Dockerfile` and `entrypoint.sh`
- reworked `README.md` / `README_DOCKER_HUB.md`, removed old launch docs

### dev_1.2.2 (functional)

Refs: `origin/dev_1.2.2`, `origin/dev_v1.2.2`, `dev_v1.2.2`

Differences (vs `dev_1.2.1`):
- heavily reworked `release.yml`
- expanded/updated `README.md` / `README_DOCKER_HUB.md`
- significantly extended `entrypoint.sh` (more logic/flows)
- small updates to the `Dockerfile`

### dev_1.2.3 (non-functional)

Refs: `origin/dev_1.2.3`, `origin/dev_v1.2.3`, `dev_v1.2.3`

Differences (vs `dev_1.2.2`):
- small tweaks to `.github/workflows/release.yml` only

### dev_2.0.0 (non-functional)

Refs: `origin/dev_2.0.0`, `origin/dev_v2.0.0`, `dev_v2.0.0`

Differences (vs `dev_1.2.3`):
- major rewrite: introduced `server_manager/` (e.g. `manager.sh` + `lib/*.sh`)
- removed `entrypoint.sh` (startup/management refactor)
- new docs: `docs/environment.md`, `docs/changelog/v2.0.0.md`
- moved Docker Hub notes to `docs/README_DOCKER_HUB.md`
- added `ressources/server_manager.json`

### dev_2.1.0 (non-functional)

Refs: `origin/dev_2.1.0`, `dev_2.1.0`

Differences (vs `dev_2.0.0`):
- Supervisor integration: `server_manager/supervisord.conf`
- new docs: `docs/log.md`, `docs/server_manager_commands.md`
- refactor: removed/moved some `lib/*` files (incl. logging/scheduler)
- updates to `Dockerfile` and `docs/environment.md`

### dev_2.1.1 (non-functional)

Refs: `origin/dev_2.1.1`, `dev_2.1.1`

Differences (vs `dev_2.1.0`):
- extended profile system:
  - new docs: `docs/profile.md`
  - new templates: `server_manager/profiles/default.json` and `server_manager/profiles/manual.json`
- additional changes in `server_manager` scripts and docs

### dev_2.1.2 (non-functional)

Refs: `origin/dev_2.1.2`, `dev_2.1.2`

Differences (vs `dev_2.1.1`):
- added `.gitattributes` + line-ending fixes (CRLF/LF)
- changelog: removed `docs/changelog/v2.0.0.md`, added `docs/changelog/v2.1.2.md`
- docs/structure:
  - `docs/profile.md` -> `docs/server_manager_profiles.md`
  - added `docs/enshrouded_profiles.md`
- templates/files moved:
  - `ressources/enshrouded_server.json` -> `server_manager/profiles_enshrouded/default/enshrouded_server.json`
  - removed `ressources/server_manager.json`
- small `Dockerfile` updates

### dev_2.1.3 (non-functional)

Refs: `origin/dev_2.1.3`, `dev_2.1.3`

Differences (vs `dev_2.1.2`):
- many documentation and workflow changes (incl. `.github/workflows/release.yml`)
- `server_manager` updates (incl. `manager.sh`, `lib/server.sh`)

### dev_2.2.0 (non-functional)

Refs: `origin/dev_2.2.0`, `dev_2.2.0`

Differences (vs `dev_2.1.3`):
- refactor: new `server_manager/lib/env.sh` + `server_manager/lib/profile.sh`
- `server_manager/lib/config.sh` heavily reduced/refactored
- renamed changelog to `docs/changelog/dev_2.2.0.md`
- updates to Supervisor config, docs, and `Dockerfile`

### dev_3.0.0 (non-functional)

Refs: `origin/dev_3.0.0`, `dev_3.0.0`

Differences (vs `dev_2.2.0`):
- major architecture refactor (towards the current layout):
  - `server_manager/entrypoints/` (`bootstrap`, `ctl`)
  - `server_manager/jobs/` (Supervisor-managed one-shot jobs)
  - `server_manager/shared/` (common/env/profile + bootstrap/updater shared)
  - `server_manager/runtimes/proton/`
  - `server_manager/supervisor/supervisord.conf`
  - split profile templates: `server_manager/profiles/manager/*` + `server_manager/profiles/enshrouded/*`
- docs updated to match the new system; many older docs removed/replaced
- new init changelog: `docs/changelog/v3.0.0.md`

### dev_3.0.1 (non-functional)

Refs: `origin/dev_3.0.1`, `dev_3.0.1`

Differences (vs `dev_3.0.0`):
- new job: `server_manager/jobs/enshrouded-password-view`
- updates in `docs/` (changelog/env/profile/commands/logs)
- small changes to `Dockerfile`, `ctl`, `bootstrap`, and `shared/profile`

### dev_3.1.0 (functional)

Refs: `origin/dev_3.1.0`, `dev_3.1.0`

Differences (vs `dev_3.0.1`):
- new interactive TTY menu: `server_manager/menu/*`
- new docs: `docs/menu.md`
- expanded backup/menu/reset flows (incl. `jobs/enshrouded-backup`, `jobs/server-manager-profil-reset`)
- added GitHub issue templates (`.github/workflows/ISSUE_TEMPLATE/*`)
- small updates to `Dockerfile`/docs; fixes (incl. `pipefail`)
