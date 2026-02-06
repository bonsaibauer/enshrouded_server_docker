# CI/CD Workflow Notes

## Branching model
- **Release tags:** `vX.Y.Z` (e.g., `v1.2.1`). Releases are driven by GitHub Releases, not by pushing version branches directly.
- **Development preview branches:** `dev_*` (e.g., `dev_1.2.1`, `dev_1.2.1/hotfix`). Pushing to these branches runs the dev build workflow.
- **Main branch:** `main` is the stable integration branch; the dev workflow does not run on it.

## Workflows
### `.github/workflows/dev.yml`
- **Triggers:** `push` on branches matching `dev_*`; ignores changes limited to `.github/**`, `README.md`, `LICENSE`.
- **Behavior:** Builds the Docker image and pushes two tags:
  - `enshrouded_server_docker:dev_latest`
  - `enshrouded_server_docker:<branch-slug>` (slashes replaced by dashes, so `dev_1.2.1/hotfix` → `dev_1.2.1-hotfix`).
- **Secrets required:** `DOCKER_USER`, `DOCKER_TOKEN`.
- **Concurrency:** Cancels any in-progress dev build for the same ref.

### `.github/workflows/release.yml`
- **Triggers:** `release` event (`published`) or manual `workflow_dispatch`.
- **Behavior:** Builds image, tags `latest` and the release tag, runs Docker Scout + Trivy scans, uploads SARIF, then pushes images on success. For releases, the Server Manager version is set to the **release tag** (e.g., `v2.1.1`). Also updates the Docker Hub description from `docs/README_DOCKER_HUB.md`.
- **Secrets required:** `DOCKER_USER`, `DOCKER_TOKEN`.
- **Concurrency:** Serialized per ref via `release-${{ github.ref }}`.

## Three-stage flow
1) **Version branch:** work on features using standard branches (e.g., `feature/...`).  
2) **Dev preview:** merge/rebase into a `dev_X.Y.Z` branch to trigger automated dev images (`dev_latest` + branch tag).  
3) **Release:** create a GitHub Release with tag `vX.Y.Z`; the release workflow builds, scans, and publishes production images.
